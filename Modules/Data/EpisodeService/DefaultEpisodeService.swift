//
//  DefaultEpisodeService.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 09..
//

import Foundation
import Combine
import UIKit

import Common
import Domain

internal import FeedKit
internal import XMLKit
internal import AudstreamerAPIClient

final class DefaultEpisodeService {

    // MARK: Dependencies

    @Injected private var client: Client
    @Injected private var database: Database
    @Injected private var downloadService: DownloadService
    @Injected private var watchConnectivityService: WatchConnectivityService
    @Injected private var cloud: Cloud
    @Injected private var applicationStateHandler: ApplicationStateHandler
    @Injected private var playingUpdater: PlayingUpdater
    @Injected private var socketUpdater: SocketUpdater
    @Injected private var databaseUpdater: DatabaseUpdater
    @Injected private var contextManager: SwiftDataContextManager
}

// MARK: - EpisodeService

extension DefaultEpisodeService: EpisodeService {
    func refresh() -> AnyPublisher<Void, Error> {
        synchronizeCloudDataToDatabase()
    }

    func episodes(matching attributes: EpisodeQueryAttributes) -> AnyPublisher<[Episode], Error> {
        database.getEpisodes(
            filterFavorites: attributes.filterFavorites,
            filterDownloads: attributes.filterDownloads,
            filterWatch: attributes.filterWatch,
            keyword: attributes.keyword,
            podcastID: attributes.podcastID
        )
        .asyncTryMap { [unowned self] in await contextManager.mapDataModels($0) }
        .eraseToAnyPublisher()
    }
    
    func episode(id: String) -> AnyPublisher<Episode?, Error> {
        database.getEpisode(id: id)
            .asyncTryMap { [unowned self] in await contextManager.mapDataModel($0) }
    }
    
    func lastPlayedEpisode() -> AnyPublisher<Episode?, Error> {
        database.getLastPlayedEpisode()
            .asyncTryMap { [unowned self] in await contextManager.mapDataModel($0) }
    }
    
    func downloadEvents() -> AnyPublisher<DownloadEvent, Error> {
        downloadService.getEvent()
    }
    
    func aggregatedDownloadEvents() -> AnyPublisher<DownloadAggregatedEvent, Error> {
        downloadService.getAggregatedEvent()
    }
    
    func aggregatedTransferEvents() -> AnyPublisher<FileTransferAggregatedProgress, Error> {
        watchConnectivityService.getAggregatedFileTransferProgress()
    }

    func startUpdating() -> AnyPublisher<Void, any Error> {
        Publishers.Zip4(
            playingUpdater.startUpdating(),
            socketUpdater.startUpdating(),
            databaseUpdater.startUpdating(),
            Just(applicationStateHandler.start()).setFailureType(to: Error.self)
        )
        .toVoid()
        .eraseToAnyPublisher()
    }

    func stopUpdating() -> AnyPublisher<Void, any Error> {
        Publishers.Zip4(
            playingUpdater.stopUpdating(),
            socketUpdater.stopUpdating(),
            databaseUpdater.stopUpdating(),
            Just(applicationStateHandler.stop()).setFailureType(to: Error.self)
        )
        .toVoid()
        .eraseToAnyPublisher()
    }

    func updateLastPlayedDate(_ lastPlayedDate: Date, for episode: Episode) -> AnyPublisher<Void, Error> {
        database.updateLastPlayedDate(for: episode.id, date: lastPlayedDate)
    }
    
    func updateLastPosition(_ lastPosition: Int, for episode: Episode) -> AnyPublisher<Void, Error> {
        database.updateLastPosition(lastPosition, for: episode.id)
    }
    
    func setFavorite(_ episode: Episode, isFavorite: Bool) -> AnyPublisher<Void, Error> {
        database.updateEpisode(episode.id, isFavorite: isFavorite)
    }
    
    func download(_ episode: Episode) -> AnyPublisher<Void, Error> {
        downloadService.download(episode, userInfo: [:])
    }
    
    func deleteDownload(for episode: Episode) -> AnyPublisher<Void, Error> {
        downloadService.delete(episode)
            .flatMap { [unowned self] in database.updateEpisode(episode.id, isDownloaded: false) }
            .eraseToAnyPublisher()
    }
    
    func deleteAllDownloads() -> AnyPublisher<Void, Error> {
        downloadService.deleteDownloads()
            .flatMap { [unowned self] in database.resetDownloadEpisodes() }
            .eraseToAnyPublisher()
    }
    
    func pauseDownload(for episode: Episode) -> AnyPublisher<Void, Error> {
        downloadService.pause(episode)
    }
    
    func resumeDownload(for episode: Episode) -> AnyPublisher<Void, Error> {
        downloadService.resume(episode)
    }
    
    func cancelDownload(for episode: Episode) -> AnyPublisher<Void, Error> {
        downloadService.cancel(episode)
    }

    func downloadsSize() -> AnyPublisher<Int, any Error> {
        downloadService.getDownloadSize()
    }

    func sendToWatch(_ episode: Episode) -> AnyPublisher<Void, Error> {
        Publishers.Zip(
            database.updateEpisode(episode.id, isOnWatch: true),
            watchConnectivityService.transferEpisode(episode.id)
        )
        .toVoid()
    }
    
    func removeFromWatch(_ episode: Episode) -> AnyPublisher<Void, Error> {
        Publishers.Zip(
            database.updateEpisode(episode.id, isOnWatch: false),
            watchConnectivityService.cancelFileTransferForEpisode(episode.id)
        )
        .toVoid()
    }
}

// MARK: - Helpers

extension DefaultEpisodeService {
    private func synchronizeCloudDataToDatabase() -> AnyPublisher<Void, Error> {
        let updateFavorites = updateFavorites()
        let updateLastPlayDates = updateLastPlayedDates()
        let updateLastPositions = updateLastPositions()

        return Publishers.Zip3(updateFavorites, updateLastPlayDates, updateLastPositions).toVoid()
    }

    private func updateFavorites() -> AnyPublisher<Void, Error> {
        cloud.getFavoriteEpisodeIDs()
            .first()
            .flatMap { [unowned self] ids -> AnyPublisher<Void, Error> in
                guard !ids.isEmpty else { return Just.void() }
                return ids.map { id in
                    database.getEpisode(id: id)
                        .first()
                        .flatMap { episode -> AnyPublisher<Void, Error> in
                            guard let episode = episode else { return Just.void() }
                            return self.database.updateEpisode(episode.id, isFavorite: true)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private func updateLastPlayedDates() -> AnyPublisher<Void, Error> {
        cloud.getLastPlayedDates()
            .first()
            .flatMap { [unowned self] playedDates -> AnyPublisher<Void, Error> in
                guard !playedDates.isEmpty else { return Just.void() }
                return playedDates.map { id, date in
                    database.getEpisode(id: id)
                        .first()
                        .flatMap { episode -> AnyPublisher<Void, Error> in
                            guard let episode = episode else { return Just.void() }
                            return self.database.updateLastPlayedDate(for: episode.id, date: date)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private func updateLastPositions() -> AnyPublisher<Void, Error> {
        cloud.getLastPositions()
            .first()
            .flatMap { [unowned self] lastPositions -> AnyPublisher<Void, Error> in
                guard !lastPositions.isEmpty else { return Just.void() }
                return lastPositions.map { id, lastPosition in
                    database.getEpisode(id: id)
                        .first()
                        .flatMap { episode -> AnyPublisher<Void, Error> in
                            guard let episode = episode else { return Just.void() }
                            return self.database.updateLastPosition(lastPosition, for: episode.id)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }
}
