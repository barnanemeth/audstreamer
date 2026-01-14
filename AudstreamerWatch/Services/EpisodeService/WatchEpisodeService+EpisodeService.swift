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
    func episode(id: String) -> AnyPublisher<Episode?, Error> {
        episodes
            .map { $0.first(where: { $0.id == id }) }
            .eraseToAnyPublisher()
    }

    func episodes(matching attributes: Domain.EpisodeQueryAttributes) -> AnyPublisher<[Domain.Episode], any Error> {
        episodes
    }

    func refresh() -> AnyPublisher<Void, any Error> {
        Just(updateTriggerSubject.send(()))
            .setFailureType(to: Error.self)
            .flatMap { [unowned self] in deleteAbandonedEpisodes() }
            .eraseToAnyPublisher()
    }

    func startUpdating() -> AnyPublisher<Void, any Error> {
        Just({
            guard cancellables.isEmpty else { return }
            subscribeToCurrentSeconds()
            subscribeToRemotePlayerEvents()
            subscribeToCurrentPlayingAudioInfo()
        }())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }

    func stopUpdating() -> AnyPublisher<Void, any Error> {
        Just(cancellables.removeAll()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func updateLastPlayedDate(_ lastPlayedDate: Date, for episode: Domain.Episode) -> AnyPublisher<Void, any Error> {
        cancelOutstandingLastPlayedDateTransfers(for: episode.id, type: LastPlayedDateMessage.self)
            .map { [unowned self] _ in
                let message = LastPlayedDateMessage(episodeID: episode.id, date: lastPlayedDate).asUserInfo
                self.session.transferUserInfo(message)
            }
            .eraseToAnyPublisher()
    }
    
    func updateLastPosition(_ lastPosition: Int, for episode: Domain.Episode) -> AnyPublisher<Void, any Error> {
        cancelOutstandingLastPlayedDateTransfers(for: episode.id, type: LastPositionMessage.self)
            .map { [unowned self] _ in
                let message = LastPositionMessage(episodeID: episode.id, position: lastPosition).asUserInfo
                self.session.transferUserInfo(message)
            }
            .eraseToAnyPublisher()
    }
}
