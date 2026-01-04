//
//  Database.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import Foundation
import Combine

public protocol Database {
    func insertEpisodes(_ episodes: [Episode], overwrite: Bool) -> AnyPublisher<Void, Error>
    func getEpisodes(filterFavorites: Bool,
                     filterDownloads: Bool,
                     filterWatch: Bool,
                     keyword: String?) -> AnyPublisher<[Episode], Error>
    func getEpisode(id: String) -> AnyPublisher<Episode?, Error>
    func getLastEpisodePublishDate() -> AnyPublisher<Date?, Error>
    func getLastPlayedEpisode() -> AnyPublisher<Episode?, Error>
    func updateEpisode(_ episode: Episode, isFavorite: Bool) -> AnyPublisher<Void, Error>
    func updateEpisode(_ episode: Episode, isOnWatch: Bool) -> AnyPublisher<Void, Error>
    func updateLastPlayedDate(for episode: Episode, date: Date) -> AnyPublisher<Void, Error>
    func updateLastPosition(_ lastPosition: Int?, for episode: Episode) -> AnyPublisher<Void, Error>
    func updateDuration(_ duration: Int, for episode: Episode) -> AnyPublisher<Void, Error>
    func updateEpisode(_ episode: Episode, isDownloaded: Bool) -> AnyPublisher<Void, Error>
    func updateNumberOfPlays(_ episode: Episode, numberOfPlays: Int) -> AnyPublisher<Void, Error>
    func incrementNumberOfPlays(of episode: Episode) -> AnyPublisher<Void, Error>
    func deleteDuplicates() -> AnyPublisher<Void, Error>
    func deleteAll() -> AnyPublisher<Void, Error>
    func deleteEpisode(with id: String) -> AnyPublisher<Void, Error>
    func deleteEpisode(_ episode: Episode) -> AnyPublisher<Void, Error>
    func resetDownloadEpisodes() -> AnyPublisher<Void, Error>
}

extension Database {
    public func insertEpisodes(_ episodes: [Episode], overwrite: Bool = false) -> AnyPublisher<Void, Error> {
        insertEpisodes(episodes, overwrite: overwrite)
    }

    public func getEpisodes(filterFavorites: Bool = false,
                            filterDownloads: Bool = false,
                            filterWatch: Bool = false,
                            keyword: String? = nil) -> AnyPublisher<[Episode], Error> {
        getEpisodes(
            filterFavorites: filterFavorites,
            filterDownloads: filterDownloads,
            filterWatch: filterWatch,
            keyword: keyword
        )
    }

    public func updateLastPlayedDate(for episode: Episode, date: Date = Date()) -> AnyPublisher<Void, Error> {
        updateLastPlayedDate(for: episode, date: date)
    }
}
