//
//  PodcastService.swift
//  Domain
//
//  Created by Barna Nemeth on 2026. 01. 20..
//

import Combine

public protocol PodcastService {
    func search(with searchTerm: String) -> AnyPublisher<[Podcast], Error>
    func getTrending() -> AnyPublisher<[Podcast], Error>
    func follow(_ podcast: Podcast) -> AnyPublisher<Void, Error>
    func unfollow(_ podcast: Podcast) -> AnyPublisher<Void, Error>
}
