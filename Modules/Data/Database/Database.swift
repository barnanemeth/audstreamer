//
//  Database.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import Foundation
import Combine
import SwiftData

import Domain

protocol Database {
    func insertEpisodes(_ episodes: [EpisodeDataModel], overwrite: Bool) -> AnyPublisher<Void, Error>
    func getEpisodes(filterFavorites: Bool,
                     filterDownloads: Bool,
                     filterWatch: Bool,
                     keyword: String?) -> AnyPublisher<[EpisodeDataModel], Error>
    func getEpisode(id: EpisodeDataModel.ID) -> AnyPublisher<EpisodeDataModel?, Error>
    func getLastEpisodePublishDate() -> AnyPublisher<Date?, Error>
    func getLastPlayedEpisode() -> AnyPublisher<EpisodeDataModel?, Error>
    func updateEpisode(_ episode: EpisodeDataModel.ID, isFavorite: Bool) -> AnyPublisher<Void, Error>
    func updateEpisode(_ episode: EpisodeDataModel.ID, isOnWatch: Bool) -> AnyPublisher<Void, Error>
    func updateLastPlayedDate(for episode: EpisodeDataModel.ID, date: Date) -> AnyPublisher<Void, Error>
    func updateLastPosition(_ lastPosition: Int?, for episode: EpisodeDataModel.ID) -> AnyPublisher<Void, Error>
    func updateDuration(_ duration: Int, for episode: EpisodeDataModel.ID) -> AnyPublisher<Void, Error>
    func updateEpisode(_ episode: EpisodeDataModel.ID, isDownloaded: Bool) -> AnyPublisher<Void, Error>
    func updateNumberOfPlays(_ episode: EpisodeDataModel.ID, numberOfPlays: Int) -> AnyPublisher<Void, Error>
    func incrementNumberOfPlays(of episode: EpisodeDataModel.ID) -> AnyPublisher<Void, Error>
    func deleteAll() -> AnyPublisher<Void, Error>
    func deleteEpisode(with id: String) -> AnyPublisher<Void, Error>
    func deleteEpisode(_ episode: EpisodeDataModel) -> AnyPublisher<Void, Error>
    func resetDownloadEpisodes() -> AnyPublisher<Void, Error>
}
