//
//  Database.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import Foundation
import Combine

protocol Database {
    func insertEpisodes(_ episodes: [EpisodeData], overwrite: Bool) -> AnyPublisher<Void, Error>
    func getEpisodes(filterFavorites: Bool,
                     filterDownloads: Bool,
                     filterWatch: Bool,
                     keyword: String?) -> AnyPublisher<[EpisodeData], Error>
    func getEpisode(id: String) -> AnyPublisher<EpisodeData?, Error>
    func getLastEpisodePublishDate() -> AnyPublisher<Date?, Error>
    func getLastPlayedEpisode() -> AnyPublisher<EpisodeData?, Error>
    func updateEpisode(_ episode: EpisodeData, isFavorite: Bool) -> AnyPublisher<Void, Error>
    func updateEpisode(_ episode: EpisodeData, isOnWatch: Bool) -> AnyPublisher<Void, Error>
    func updateLastPlayedDate(for episode: EpisodeData, date: Date) -> AnyPublisher<Void, Error>
    func updateLastPosition(_ lastPosition: Int?, for episode: EpisodeData) -> AnyPublisher<Void, Error>
    func updateDuration(_ duration: Int, for episode: EpisodeData) -> AnyPublisher<Void, Error>
    func updateEpisode(_ episode: EpisodeData, isDownloaded: Bool) -> AnyPublisher<Void, Error>
    func updateNumberOfPlays(_ episode: EpisodeData, numberOfPlays: Int) -> AnyPublisher<Void, Error>
    func incrementNumberOfPlays(of episode: EpisodeData) -> AnyPublisher<Void, Error>
    func deleteDuplicates() -> AnyPublisher<Void, Error>
    func deleteAll() -> AnyPublisher<Void, Error>
    func deleteEpisode(with id: String) -> AnyPublisher<Void, Error>
    func deleteEpisode(_ episode: EpisodeData) -> AnyPublisher<Void, Error>
    func resetDownloadEpisodes() -> AnyPublisher<Void, Error>
}

extension Database {
    func insertEpisodes(_ episodes: [EpisodeData], overwrite: Bool = false) -> AnyPublisher<Void, Error> {
        insertEpisodes(episodes, overwrite: overwrite)
    }

    func getEpisodes(filterFavorites: Bool = false,
                     filterDownloads: Bool = false,
                     filterWatch: Bool = false,
                     keyword: String? = nil) -> AnyPublisher<[EpisodeData], Error> {
        getEpisodes(
            filterFavorites: filterFavorites,
            filterDownloads: filterDownloads,
            filterWatch: filterWatch,
            keyword: keyword
        )
    }

    func updateLastPlayedDate(for episode: EpisodeData, date: Date = Date()) -> AnyPublisher<Void, Error> {
        updateLastPlayedDate(for: episode, date: date)
    }
}
