//
//  MockEpisodeService.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 17..
//

import Foundation
import Combine

import Domain

struct MockWatchEpisodeService { }

// MARK: - EpisodeService

extension MockWatchEpisodeService: EpisodeService {
    func startUpdating() -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func stopUpdating() -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func download(_ episode: Domain.Episode) -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func episodes(matching attributes: Domain.EpisodeQueryAttributes) -> AnyPublisher<[Domain.Episode], any Error> {
        Empty().eraseToAnyPublisher()
    }

    func episode(id: String) -> AnyPublisher<Domain.Episode?, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func lastPlayedEpisode() -> AnyPublisher<Domain.Episode?, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func downloadEvents() -> AnyPublisher<Domain.DownloadEvent, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func aggregatedDownloadEvents() -> AnyPublisher<Domain.DownloadAggregatedEvent, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func aggregatedTransferEvents() -> AnyPublisher<Domain.FileTransferAggregatedProgress, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func refresh() -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func updateLastPlayedDate(_ lastPlayedDate: Date, for episode: Domain.Episode) -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func updateLastPosition(_ lastPosition: Int, for episode: Domain.Episode) -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func setFavorite(_ episode: Domain.Episode, isFavorite: Bool) -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func deleteDownload(for episode: Domain.Episode) -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func deleteAllDownloads() -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func pauseDownload(for episode: Domain.Episode) -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func resumeDownload(for episode: Domain.Episode) -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func cancelDownload(for episode: Domain.Episode) -> AnyPublisher<Void, any Error> {
        Empty().eraseToAnyPublisher()
    }

    func downloadsSize() -> AnyPublisher<Int, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func getEpisodes() -> AnyPublisher<[Episode], any Error> {
        let episodes = [Episode]()
        return Just(episodes).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func updateLastPlayedDate(_ lastPlayedDate: Date, for episodeID: String) -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func updateLastPosition(_ lastPosition: Int, for episodeID: String) -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func deleteAbandonedEpisodes() -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func sendUpdateTrigger() -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
}
