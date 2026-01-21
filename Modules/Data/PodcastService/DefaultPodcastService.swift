//
//  DefaultPodcastService.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 20..
//

import Combine

import Domain

final class DefaultPodcastService {

}

// MARK: - PodcastService

extension DefaultPodcastService: PodcastService {
    func search(with searchTerm: String) -> AnyPublisher<[Podcast], Error> {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
    
    func getTrending() -> AnyPublisher<[Podcast], Error> {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
    
    func follow(_ podcast: Podcast) -> AnyPublisher<Void, Error> {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
    
    func unfollow(_ podcast: Podcast) -> AnyPublisher<Void, Error> {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
}
