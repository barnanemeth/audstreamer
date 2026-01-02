//
//  WatchEpisodeService+DownloadService.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 14..
//

import Foundation
import Combine

import Common
import Domain

// MARK: - DownloadService

extension WatchEpisodeService: DownloadService {
    func download(_ item: Downloadable, userInfo: [String: Any]) -> AnyPublisher<Void, Error> {
        guard session.isReachable else {
            return Fail(error: DownloadServiceError.connectionUnavailable).eraseToAnyPublisher()
        }
        return Promise { [unowned self] promise in
            self.session.sendMessage(
                EpisodeRequestMessage(episodeID: item.id).asUserInfo,
                replyHandler: { reply in
                    guard let replyMessage = ReplyMessage(from: reply), replyMessage.status == .success else {
                        return promise(.failure(DownloadServiceError.connectionUnavailable))
                    }
                    promise(.success(()))
                },
                errorHandler: { promise(.failure($0)) })
        }
        .eraseToAnyPublisher()
    }

    func delete(_ item: Downloadable) -> AnyPublisher<Void, Error> {
        guard let url = WatchURLHelper.getURLForEpisode(item.id) else { return Just.void() }
        do {
            try fileManager.removeItem(at: url)
            return Just.void()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func getEvent() -> AnyPublisher<DownloadEvent, Error> {
        Empty<DownloadEvent, Error>(completeImmediately: false).eraseToAnyPublisher()
    }

    func getAggregatedEvent() -> AnyPublisher<DownloadAggregatedEvent, Error> {
        Empty<DownloadAggregatedEvent, Error>(completeImmediately: false).eraseToAnyPublisher()
    }

    func getDownloadSize() -> AnyPublisher<Int, Error> {
        Just(.zero).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func refreshDownloadSize() -> AnyPublisher<Void, Error> {
        Just.void()
    }

    func deleteDownloads() -> AnyPublisher<Void, Error> {
        Just.void()
    }

    func pause(_ item: Downloadable) -> AnyPublisher<Void, Error> {
        Just.void()
    }

    func resume(_ item: Downloadable) -> AnyPublisher<Void, Error> {
        Just.void()
    }

    func cancel(_ item: Downloadable) -> AnyPublisher<Void, Error> {
        Just.void()
    }

    func isDownloaded(_ item: Downloadable) -> AnyPublisher<Bool, Error> {
        guard let url = WatchURLHelper.getURLForEpisode(item.id) else {
            return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        let isExits = fileManager.fileExists(atPath: url.path)
        return Just(isExits).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
