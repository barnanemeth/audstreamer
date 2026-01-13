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
        Empty().eraseToAnyPublisher()
    }

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
