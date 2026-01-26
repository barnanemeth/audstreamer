//
//  PodcastService.swift
//  Domain
//
//  Created by Barna Nemeth on 2026. 01. 20..
//

import Foundation
import Combine

public protocol PodcastService {
    func refresh() -> AnyPublisher<Void, Error>
    func search(with searchTerm: String) -> AnyPublisher<[Podcast], Error>
    func podcast(id: Podcast.ID) -> AnyPublisher<Podcast?, Error>
    func getTrending(maximumResult: Int?) -> AnyPublisher<[Podcast], Error>
    func subscribe(to podcast: Podcast) -> AnyPublisher<Void, Error>
    func unsubscribe(from podcast: Podcast) -> AnyPublisher<Void, Error>
    func savedPodcasts() -> AnyPublisher<[Podcast], Error>
    func addPodcastFeed(_ feedURL: URL) -> AnyPublisher<Void, Error>
}
