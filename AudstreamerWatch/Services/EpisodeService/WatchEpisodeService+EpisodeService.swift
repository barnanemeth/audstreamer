//
//  WatchEpisodeService+EpisodeService.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 14..
//

import Foundation
import Combine

import Common
import Domain

// MARK: - EpisodesService

extension WatchEpisodeService: EpisodeService {
    func getEpisodes() -> AnyPublisher<[Episode], Error> {
        episodes
    }

    func updateLastPlayedDate(_ lastPlayedDate: Date, for episodeID: String) -> AnyPublisher<Void, Error> {
        cancelOutstandingLastPlayedDateTransfers(for: episodeID, type: LastPlayedDateMessage.self)
            .map { [unowned self] _ in
                let message = LastPlayedDateMessage(episodeID: episodeID, date: lastPlayedDate).asUserInfo
                self.session.transferUserInfo(message)
            }
            .eraseToAnyPublisher()
    }

    func updateLastPosition(_ lastPosition: Int, for episodeID: String) -> AnyPublisher<Void, Error> {
        cancelOutstandingLastPlayedDateTransfers(for: episodeID, type: LastPositionMessage.self)
            .map { [unowned self] _ in
                let message = LastPositionMessage(episodeID: episodeID, position: lastPosition).asUserInfo
                self.session.transferUserInfo(message)
            }
            .eraseToAnyPublisher()
    }

    func deleteAbandonedEpisodes() -> AnyPublisher<Void, Error> {
        Promise { promise in
            DispatchQueue.global(qos: .background).async {
                do {
                    let episodes = try self.decodeEpisodes(from: self.userDefaults.episodesData)
                    let downloadedEpisodes = self.urlsForDownloadedEpisodes()

                    try downloadedEpisodes.forEach { episodeURL in
                        let episodeID = episodeURL.deletingPathExtension().lastPathComponent
                        guard !episodes.contains(where: { $0.id == episodeID }) else { return }
                        try self.fileManager.removeItem(at: episodeURL)

                        promise(.success(()))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sendUpdateTrigger() -> AnyPublisher<Void, Error> {
        Just(updateTriggerSubject.send(())).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
