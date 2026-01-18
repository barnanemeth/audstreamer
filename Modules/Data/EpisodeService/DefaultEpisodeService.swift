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

final class DefaultEpisodeService {

    // MARK: Dependencies

    @Injected private var apiClient: APIClient
    @Injected private var database: Database
    @Injected private var downloadService: DownloadService
    @Injected private var watchConnectivityService: WatchConnectivityService
    @Injected private var cloud: Cloud
    @Injected private var applicationStateHandler: ApplicationStateHandler
    @Injected private var playingUpdater: PlayingUpdater
    @Injected private var socketUpdater: SocketUpdater
    @Injected private var databaseUpdater: DatabaseUpdater
}

// MARK: - EpisodeService

extension DefaultEpisodeService: EpisodeService {
    func episodes(matching attributes: EpisodeQueryAttributes) -> AnyPublisher<[Episode], Error> {
        database.getEpisodes(
            filterFavorites: attributes.filterFavorites,
            filterDownloads: attributes.filterDownloads,
            filterWatch: attributes.filterWatch,
            keyword: attributes.keyword
        )
    }
    
    func episode(id: String) -> AnyPublisher<Episode?, Error> {
        database.getEpisode(id: id)
    }
    
    func lastPlayedEpisode() -> AnyPublisher<Episode?, Error> {
        database.getLastPlayedEpisode()
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
    
    func refresh() -> AnyPublisher<Void, Error> {
//        let isApplicationActivePublisher = applicationStateHandler.getState().map { $0 == .active }
//
//        return isApplicationActivePublisher
//            .flatMap { isActive in
//                if isActive {
//                    Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
//                } else {
//                    Empty<Void, Error>(completeImmediately: false).eraseToAnyPublisher()
//                }
//            }
//            .flatMap { [unowned self] _ in database.getLastEpisodePublishDate().first() }
//            .flatMap { [unowned self] lastPublishDate -> AnyPublisher<([Episode], Int), Error> in
//                let remoteEpisodes = apiClient.getEpisodes(from: lastPublishDate)
//                let localEpisodesCount = getEpisodesCount()
//
//                return Publishers.Zip(remoteEpisodes, localEpisodesCount).eraseToAnyPublisher()
//            }
//            .flatMap { [unowned self] remoteEpisodes, localEpisodesCount in
//                let isOverwriteNeeded = remoteEpisodes.count >= localEpisodesCount
//                return database.insertEpisodes(remoteEpisodes, overwrite: isOverwriteNeeded)
//            }
//            .flatMap { [unowned self] in synchronizeCloudDataToDatabase() }
//            .replaceEmpty(with: ())
//            .eraseToAnyPublisher()

        let feedURL = URL(string: "https://omny.fm/shows/borizuhang/playlists/podcast.rss?accessToken=eyJraWQiOiJMQVpfcFBpLVUwV2dxYTZ2QU02UWxnIiwiYWxnIjoiSFMyNTYiLCJ0eXAiOiJKV1QifQ.eyJwbGF5bGlzdCI6IjMxZDBlZmVhLTQ1OTEtNDQwYS04MDg4LWFlYWQwMGQ1NjFmZCIsImtleSI6IlhmZXBlQ3BGd2txTDhaYlhRa2xESHcifQ.ccWmOqSda8HhBbhpjInj8_mdz8ehPvQ_MhEsZ5QiOso")!
        return URLSession.shared.dataTaskPublisher(for: feedURL)
            .tryMap { data, _ -> RSSFeed in
                try RSSFeed(data: data)
            }
            .tryMap { rssFeed -> Podcast in
                guard let channel = rssFeed.channel, let title = channel.title else { throw URLError(.unknown) }
                let episodes = channel.items?.compactMap { (item: RSSFeedItem) -> Episode? in
                    guard let title = item.title else { return nil }
                    return Episode(
                        id: item.guid?.text ?? UUID().uuidString,
                        title: title,
                        publishDate: item.pubDate ?? .now,
                        descriptionText: item.description,
                        mediaURL: {
                            if let string = item.enclosure?.attributes?.url {
                                URL(string: string)!
                            } else {
                                URL(string: "")!
                            }
                        }(),
                        image: {
                            if let string = item.iTunes?.image?.attributes?.href ?? channel.image?.link {
                                URL(string: string)!
                            } else {
                                nil
                            }
                        }(),
                        thumbnail: {
                            if let string = item.iTunes?.image?.attributes?.href ?? channel.image?.link {
                                URL(string: string)!
                            } else {
                                nil
                            }
                        }(),
                        link: nil,
                        duration: Int(item.iTunes?.duration ?? .zero)
                    )
                }
                return Podcast(id: feedURL.absoluteString, name: title, rssFeedURL: feedURL, episodes: episodes ?? [])
            }
            .flatMap { [unowned self] podcast in
                database.insertPodcasts([podcast])
            }
            .eraseToAnyPublisher()
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
        database.updateLastPlayedDate(for: episode, date: lastPlayedDate)
    }
    
    func updateLastPosition(_ lastPosition: Int, for episode: Episode) -> AnyPublisher<Void, Error> {
        database.updateLastPosition(lastPosition, for: episode)
    }
    
    func setFavorite(_ episode: Episode, isFavorite: Bool) -> AnyPublisher<Void, Error> {
        database.updateEpisode(episode, isFavorite: isFavorite)
    }
    
    func download(_ episode: Episode) -> AnyPublisher<Void, Error> {
        downloadService.download(episode, userInfo: [:])
    }
    
    func deleteDownload(for episode: Episode) -> AnyPublisher<Void, Error> {
        downloadService.delete(episode)
            .flatMap { [unowned self] in database.updateEpisode(episode, isDownloaded: false) }
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
            database.updateEpisode(episode, isOnWatch: true),
            watchConnectivityService.transferEpisode(episode.id)
        )
        .toVoid()
    }
    
    func removeFromWatch(_ episode: Episode) -> AnyPublisher<Void, Error> {
        Publishers.Zip(
            database.updateEpisode(episode, isOnWatch: false),
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
                            return self.database.updateEpisode(episode, isFavorite: true)
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
                            return self.database.updateLastPlayedDate(for: episode, date: date)
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
                            return self.database.updateLastPosition(lastPosition, for: episode)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private func getEpisodesCount() -> AnyPublisher<Int, Error> {
        database.getEpisodes()
            .first()
            .map { $0.count }
            .eraseToAnyPublisher()
    }
}
