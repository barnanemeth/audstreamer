//
//  EpisodesService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 04..
//

import Foundation
import Combine

public protocol EpisodeService {
    func episodes(matching attributes: EpisodeQueryAttributes) -> AnyPublisher<[Episode], Error>
    func episode(id: String) -> AnyPublisher<Episode?, Error>

    func refresh() -> AnyPublisher<Void, Error>
    func startUpdating() -> AnyPublisher<Void, Error>
    func stopUpdating() -> AnyPublisher<Void, Error>
    func updateLastPlayedDate(_ lastPlayedDate: Date, for episode: Episode) -> AnyPublisher<Void, Error>
    func updateLastPosition(_ lastPosition: Int, for episode: Episode) -> AnyPublisher<Void, Error>

    #if os(iOS)
    func lastPlayedEpisode() -> AnyPublisher<Episode?, Error>
    func downloadEvents() -> AnyPublisher<DownloadEvent, Error>
    func aggregatedDownloadEvents() -> AnyPublisher<DownloadAggregatedEvent, Error>
    func aggregatedTransferEvents() -> AnyPublisher<FileTransferAggregatedProgress, Error>

    func setFavorite(_ episode: Episode, isFavorite: Bool) -> AnyPublisher<Void, Error>
    func download(_ episode: Episode) -> AnyPublisher<Void, Error>
    func deleteDownload(for episode: Episode) -> AnyPublisher<Void, Error>
    func deleteAllDownloads() -> AnyPublisher<Void, Error>
    func pauseDownload(for episode: Episode) -> AnyPublisher<Void, Error>
    func resumeDownload(for episode: Episode) -> AnyPublisher<Void, Error>
    func cancelDownload(for episode: Episode) -> AnyPublisher<Void, Error>
    func downloadsSize() -> AnyPublisher<Int, Error>
    func sendToWatch(_ episode: Episode) -> AnyPublisher<Void, Error>
    func removeFromWatch(_ episode: Episode) -> AnyPublisher<Void, Error>
    #endif
}
