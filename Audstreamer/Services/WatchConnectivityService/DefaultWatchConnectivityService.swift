//
//  DefaultWatchConnectivityService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import Foundation
import Combine
import WatchConnectivity

enum DefaultWatchConnectivityServiceError: Error {
    case resourceNotFound
}

final class DefaultWatchConnectivityService: NSObject {

    // MARK: Constants

    private enum Constant {
        static let episodesMessageKey = "episodes"
        static let queueQoS: QualityOfService = .background
        static let queueConcurrentOperationNumber = 128
    }

    // MARK: Dependencies

    @Injected private var database: Database
    @Injected private var downloadService: DownloadService

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var deletableEpisodeIDs = Set<String>()
    private let fileTransferQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = Constant.queueQoS
        queue.maxConcurrentOperationCount = Constant.queueConcurrentOperationNumber
        return queue
    }()
    private lazy var session: WCSession = {
        let session = WCSession.default
        session.delegate = self
        return session
    }()
    private let activationStatSubject = CurrentValueSubject<WCSessionActivationState, Error>(.notActivated)
    private var isReachable: AnyPublisher<Bool, Error> {
        session.publisher(for: \.isReachable)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    private var activationStatus: AnyPublisher<WCSessionActivationState, Error> {
        session.publisher(for: \.activationState)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    // MARK: Init

    override init() {
        super.init()

        setupSession()
    }
}

// MARK: - WatchConnectivityService

extension DefaultWatchConnectivityService: WatchConnectivityService {
    func startUpdating() {
        guard cancellables.isEmpty else { return }

        database.getEpisodes(filterWatch: true)
            .map { [unowned self] in self.mapEpisodes($0) }
            .replaceError(with: [:])
            .sink { [unowned self] message in
                do {
                    try self.session.updateApplicationContext(message)
                } catch {
                    print("Error while updating application context", message)
                }
            }
            .store(in: &cancellables)
    }

    func stopUpdating() {
        guard !cancellables.isEmpty else { return }
        cancellables.removeAll()
    }

    func isAvailable() -> AnyPublisher<Bool, Error> {
        guard WCSession.isSupported() else { return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher() }

        let isWatchAppInstalled = session.publisher(for: \.isWatchAppInstalled)
            .setFailureType(to: Error.self)
            .removeDuplicates()
        let isPaired = session.publisher(for: \.isPaired)
            .setFailureType(to: Error.self)
            .removeDuplicates()
        return Publishers.CombineLatest(isWatchAppInstalled, isPaired)
            .map { $0 && $1 }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func isConnected() -> AnyPublisher<Bool, Error> {
        Publishers.CombineLatest(activationStatus, isReachable)
            .map { $0 == .activated && $1 }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getAggregatedFileTransferProgress() -> AnyPublisher<FileTransferAggregatedProgress, Error> {
        fileTransferQueue.publisher(for: \.operations)
            .map { [unowned self] operations -> AnyPublisher<[Double], Never> in
                guard !operations.isEmpty else { return Just([]).eraseToAnyPublisher() }
                return self.fileTransferOperations(from: operations)
                    .map { $0.progressPublisher.removeDuplicates() }
                    .zip()
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .setFailureType(to: Error.self)
            .map { [unowned self] in self.getFileTransferAggregatedProgress(from: $0) }
            .eraseToAnyPublisher()
    }

    func transferEpisode(_ episodeID: String) -> AnyPublisher<Void, Error> {
        database.getEpisode(id: episodeID)
            .first()
            .tryMap { episode in
                guard let episode else {
                    throw DefaultWatchConnectivityServiceError.resourceNotFound
                }
                return episode
            }
            .flatMap { [unowned self] episode -> AnyPublisher<EpisodeData, Error> in
                if episode.isDownloaded {
                    return Just(episode).setFailureType(to: Error.self).eraseToAnyPublisher()
                } else {
                    return self.downloadEpisodeAndWaitForFinish(episode)
                }
            }
            .tryMap { [unowned self] episode in
                guard let localURL = episode.possibleLocalURL else {
                    throw DefaultWatchConnectivityServiceError.resourceNotFound
                }
                let episodeMetadata = EpisodeTransferMetadata(episodeID: episode.id)
                let fileTransfer = self.session.transferFile(localURL, metadata: episodeMetadata.asUserInfo)
                let operation = FileTransferOperation(fileTransfer: fileTransfer)
                self.fileTransferQueue.addOperation(operation)
            }
            .eraseToAnyPublisher()
    }

    func cancelFileTransferForEpisode(_ episodeID: String) -> AnyPublisher<Void, Error> {
        let fileTransferOperations = fileTransferOperations(from: fileTransferQueue.operations)
        guard let cancellableOperation = fileTransferOperations.first(where: { $0.id == episodeID }) else {
            return Just.void()
        }
        cancellableOperation.cancel()
        return Just.void()
    }
}

// MARK: - Helpers

extension DefaultWatchConnectivityService {
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        session.activate()
    }

    private func populateQueueIfNeeded() {
        guard !session.outstandingFileTransfers.isEmpty else { return }
        let idsInQueue = fileTransferQueue.operations.compactMap { ($0 as? FileTransferOperation)?.id }
        session.outstandingFileTransfers.forEach { fileTransfer in
            guard let id = fileTransfer.id, !idsInQueue.contains(id) else { return }
            let operation = FileTransferOperation(fileTransfer: fileTransfer)
            fileTransferQueue.addOperation(operation)
        }
    }

    private func mapEpisodes(_ episodes: [EpisodeData]) -> [String: Any] {
        let array = episodes.compactMap { EpisodeCommon(from: $0)?.asDictionary }
        return [Constant.episodesMessageKey: array]
    }

    private func getWatchConnectvitityMessage(for message: [String: Any]) -> WatchConnectivityMessage? {
        var watchConnectivityMessage: WatchConnectivityMessage?
        for messageKey in WatchConnectivityMessageKey.allCases {
            guard let message = messageKey.modelType.init(from: message) else { continue }
            watchConnectivityMessage = message
        }
        return watchConnectivityMessage
    }

//    private func handleEpisodeRequestMessage(_ message: EpisodeRequestMessage,
//                                             replyHandler: @escaping ([String: Any]) -> Void) {
//        database.getEpisode(id: message.episodeID)
//            .first()
//            .tryMap { episode in
//                guard let episode else {
//                    throw DefaultWatchConnectivityServiceError.resourceNotFound
//                }
//                return episode
//            }
//            .flatMap { [unowned self] episode -> AnyPublisher<EpisodeData, Error> in
//                if episode.isDownloaded {
//                    return Just(episode).setFailureType(to: Error.self).eraseToAnyPublisher()
//                } else {
//                    return self.downloadEpisodeAndWaitForFinish(episode)
//                }
//            }
//            .sink(receiveCompletion: { completion in
//                guard case .failure = completion else { return }
//                replyHandler(ReplyMessage(status: .failed).asUserInfo)
//            }, receiveValue: { [unowned self] episode in
//                guard let localURL = episode.possibleLocalURL else {
//                    return replyHandler(ReplyMessage(status: .failed).asUserInfo)
//                }
//                let episodeMetadata = EpisodeTransferMetadata(episodeID: episode.id)
//                let fileTransfer = self.session.transferFile(localURL, metadata: episodeMetadata.asUserInfo)
//                let operation = FileTransferOperation(fileTransfer: fileTransfer)
//                self.fileTransferQueue.addOperation(operation)
//
//                replyHandler(ReplyMessage(status: .success).asUserInfo)
//            })
//            .store(in: &cancellables)
//    }

    private func downloadEpisodeAndWaitForFinish(_ episode: EpisodeData) -> AnyPublisher<EpisodeData, Error> {
        downloadService.download(episode)
            .flatMap { [unowned self] in self.downloadService.getEvent() }
            .first { event in
                guard case .finished = event else { return false }
                return event.item.id == episode.id
            }
            .handleEvents(receiveOutput: { [unowned self] in self.deletableEpisodeIDs.insert($0.item.id) })
            .map { _ in episode }
            .eraseToAnyPublisher()
    }

    private func getFileTransferAggregatedProgress(from progresses: [Double]) -> FileTransferAggregatedProgress {
        guard !progresses.isEmpty else { return FileTransferAggregatedProgress(numberOfItems: .zero, progress: .zero) }
        let averageProgress: Double = progresses.reduce(0, +) / Double(progresses.count)
        return FileTransferAggregatedProgress(numberOfItems: progresses.count, progress: averageProgress)
    }

    private func fileTransferOperations(from operations: [Operation]) -> [FileTransferOperation] {
        operations.compactMap { $0 as? FileTransferOperation }
    }

    private func handleDictionaryData(_ dictionary: [String: Any],
                                      replyHandler: (([String: Any]) -> Void)? = nil) {
        DispatchQueue.main.async {
            switch self.getWatchConnectvitityMessage(for: dictionary) {
//            case let episodeRequestMessage as EpisodeRequestMessage:
//                guard let replyHandler else { return }
//                self.handleEpisodeRequestMessage(episodeRequestMessage, replyHandler: replyHandler)
            case let lastPlayedDateMessage as LastPlayedDateMessage:
                self.updateLastPlayedDate(with: lastPlayedDateMessage)
            case let lastPositionMessage as LastPositionMessage:
                self.updateLastPosition(with: lastPositionMessage)
            default:
                return
            }
        }
    }

    private func getEpisode(for episodeBasedMessage: WatchConnectivityEpisodeBasedMessage) -> AnyPublisher<EpisodeData?, Error> {
        database.getEpisode(id: episodeBasedMessage.episodeID)
            .first()
            .eraseToAnyPublisher()
    }

    private func updateLastPlayedDate(with lastPlayedDateMessage: LastPlayedDateMessage) {
        getEpisode(for: lastPlayedDateMessage)
            .flatMap { [unowned self] episode -> AnyPublisher<Void, Error> in
                guard let episode else { return Just.void() }
                return self.database.updateLastPlayedDate(for: episode, date: lastPlayedDateMessage.date)
            }
            .sink()
            .store(in: &cancellables)
    }

    private func updateLastPosition(with lastPositionMessage: LastPositionMessage) {
        getEpisode(for: lastPositionMessage)
            .flatMap { [unowned self] episode -> AnyPublisher<Void, Error> in
                guard let episode else { return Just.void() }
                return self.database.updateLastPosition(lastPositionMessage.position, for: episode)
            }
            .sink()
            .store(in: &cancellables)
        }
}

// MARK: - WCSessionDelegate methods

extension DefaultWatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        guard error == nil else { return }
        populateQueueIfNeeded()
    }

    func sessionDidBecomeInactive(_ session: WCSession) { }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        handleDictionaryData(message, replyHandler: replyHandler)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleDictionaryData(userInfo)
    }
}
