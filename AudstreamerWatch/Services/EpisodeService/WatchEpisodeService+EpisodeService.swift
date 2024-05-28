//
//  WatchEpisodeService+EpisodeService.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 14..
//

import Foundation
import Combine

// MARK: - EpisodesService

extension WatchEpisodeService: EpisodeService {
    func getEpisodes() -> AnyPublisher<[EpisodeCommon], Error> {
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
}
