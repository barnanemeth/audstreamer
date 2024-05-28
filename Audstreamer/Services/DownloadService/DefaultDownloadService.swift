//
//  DefaultDownloadService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 04..
//

import Foundation
import Combine

final class DefaultDownloadService {

    // MARK: Constants

    private enum Constant {
        static let queueQoS: QualityOfService = .background
        static let queueConcurrentOperationNumber = 3
        static let receiveQueue: DispatchQueue = .main
        static let aggregatedPrecisionCoefficient = 2 << 12
    }

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    private let eventSubject = PassthroughSubject<DownloadEvent, Error>()
    private let sizeSubject = CurrentValueSubject<Int, Error>(.zero)
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = Constant.queueQoS
        queue.maxConcurrentOperationCount = Constant.queueConcurrentOperationNumber
        return queue
    }()
    private lazy var itemsInQueue: AnyPublisher<[DownloadItem], Error> = {
        queue.publisher(for: \.operations)
            .setFailureType(to: Error.self)
            .map { [unowned self] in self.getItems(from: $0) }
            .shareReplay()
            .eraseToAnyPublisher()
    }()

    // MARK: Init

    init() {
        refreshSize()
    }
}

// MARK: - DownloadService

extension DefaultDownloadService: DownloadService {
    func download(_ item: Downloadable, userInfo: [String: Any]) -> AnyPublisher<Void, Error> {
        guard !isItemInQueue(item) else { return Just.void() }

        let downloadItem = DownloadItem(from: item, userInfo: userInfo)
        let operation = DownloadOperation(item: downloadItem)

        operation.eventPublisher
            .handleEvents(receiveOutput: { [unowned self] _ in self.refreshSize() })
            .append(Empty(completeImmediately: false))
            .subscribe(eventSubject)
            .store(in: &cancellables)

        defer { eventSubject.send(.queued(item: downloadItem)) }
        return Just(queue.addOperation(operation)).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func delete(_ item: Downloadable) -> AnyPublisher<Void, Error> {
        do {
            guard let url = item.possibleLocalURL else { return Just.void() }
            try fileManager.removeItem(at: url)
            refreshSize()
            eventSubject.send(.deleted(item: item))
            return Just.void()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func getEvent() -> AnyPublisher<DownloadEvent, Error> {
        eventSubject
            .receive(on: Constant.receiveQueue)
            .eraseToAnyPublisher()
    }

    func getAggregatedEvent() -> AnyPublisher<DownloadAggregatedEvent, Error> {
        Publishers.CombineLatest(eventSubject, itemsInQueue)
            .scan([DownloadItem: Progress](), { [unowned self] progresses, item in
                self.progressDictionary(dictionary: progresses, event: item.0, itemsInQueue: item.1)
            })
            .map { [unowned self] in self.aggregateItems(from: $0) }
            .removeDuplicates()
            .filter { !$0.items.isEmpty }
            .eraseToAnyPublisher()
    }

    func getDownloadSize() -> AnyPublisher<Int, Error> {
        sizeSubject.eraseToAnyPublisher()
    }

    func refreshDownloadSize() -> AnyPublisher<Void, Error> {
        Just(refreshSize()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func deleteDownloads() -> AnyPublisher<Void, Error> {
        guard let url = URLHelper.destinationDirectory else {
            return Fail(error: DownloadServiceError.badDirectoryURL).eraseToAnyPublisher()
        }
        do {
            try fileManager.removeItem(at: url)
            refreshSize()
            return Just.void()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func pause(_ item: Downloadable) -> AnyPublisher<Void, Error> {
        Just(operation(for: item)?.suspend() ?? ()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func resume(_ item: Downloadable) -> AnyPublisher<Void, Error> {
        Just(operation(for: item)?.resume() ?? ()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func cancel(_ item: Downloadable) -> AnyPublisher<Void, Error> {
        Just(operation(for: item)?.cancel() ?? ()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func isDownloaded(_ item: Downloadable) -> AnyPublisher<Bool, Error> {
        guard let url = item.possibleLocalURL else {
            return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        let isExits = fileManager.fileExists(atPath: url.path)
        return Just(isExits).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultDownloadService {
    private func isItemInQueue(_ item: Downloadable) -> Bool {
        queue.operations.compactMap { $0 as? DownloadOperation }.contains { $0.id == item.id }
    }

    private func refreshSize() {
        guard let path = URLHelper.destinationDirectory else { return }
        do {
            let directoryContent = try fileManager.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: [.totalFileAllocatedSizeKey]
            )
            let sum = try directoryContent.reduce(0, { sum, url in
                let fileSize = try url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize
                return sum + (fileSize ?? .zero)
            })

            sizeSubject.send(sum)
        } catch {
            sizeSubject.send(.zero)
        }
    }

    private func getItems(from operations: [Operation]) -> [DownloadItem] {
        operations.compactMap { ($0 as? DownloadOperation)?.item as? DownloadItem }
    }

    private func progressDictionary(dictionary: [DownloadItem: Progress],
                                    event: DownloadEvent,
                                    itemsInQueue: [DownloadItem]) -> [DownloadItem: Progress] {
        guard !itemsInQueue.isEmpty else { return [:] }
        return itemsInQueue.reduce(into: dictionary, { dictionary, item in
            if dictionary[item] == nil {
                dictionary[item] = Progress()
            } else if case let .inProgress(item, progress) = event, let downloadItem = item as? DownloadItem {
                dictionary[downloadItem] = progress
            }
        })
    }

    private func aggregateItems(from dictionary: [DownloadItem: Progress]) -> DownloadAggregatedEvent {
        let totalUnitCount = dictionary.keys.count * Constant.aggregatedPrecisionCoefficient
        var aggregatedFractionsCompleted = dictionary.reduce(into: .zero, { $0 += $1.value.fractionCompleted })
        aggregatedFractionsCompleted *= Double(Constant.aggregatedPrecisionCoefficient)

        let keysArray = Array(dictionary.keys)

        if dictionary.allSatisfy({ $0.value.isFinished }) {
            aggregatedFractionsCompleted = Double(totalUnitCount)
        }

        let progress = Progress(totalUnitCount: Int64(totalUnitCount))
        progress.completedUnitCount = Int64(aggregatedFractionsCompleted)

        let mergedUserInfo: [String: Any] = dictionary.reduce(into: [:], { userInfo, item in
            userInfo.merge(item.key.userInfo ?? [:], uniquingKeysWith: { _, newValue in newValue })
        })

        return DownloadAggregatedEvent(items: keysArray, progress: progress, userInfo: mergedUserInfo)
    }

    private func operation(for item: Downloadable) -> DownloadOperation? {
        queue.operations.first { operation in
            guard let downloadOperation = operation as? DownloadOperation else { return false }
            return downloadOperation.item.id == item.id
        } as? DownloadOperation
    }
}
