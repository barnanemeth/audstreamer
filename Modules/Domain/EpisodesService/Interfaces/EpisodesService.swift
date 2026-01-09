//
//  EpisodesService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 04..
//

import Foundation
import Combine

public protocol EpisodeService {
    func getEpisodes() -> AnyPublisher<[Episode], Error>
    func updateLastPlayedDate(_ lastPlayedDate: Date, for episodeID: String) -> AnyPublisher<Void, Error>
    func updateLastPosition(_ lastPosition: Int, for episodeID: String) -> AnyPublisher<Void, Error>
    func deleteAbandonedEpisodes() -> AnyPublisher<Void, Error>
    func sendUpdateTrigger() -> AnyPublisher<Void, Error>
}
