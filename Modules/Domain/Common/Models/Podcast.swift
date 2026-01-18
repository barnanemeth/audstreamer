//
//  Podcast.swift
//  Domain
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import Foundation

public struct Podcast: Identifiable, Hashable, Equatable {

    // MARK: Properties

    public let id: String
    public let name: String
    public let rssFeedURL: URL
    public let episodes: [Episode]

    // MARK: Init

    public init(id: String, name: String, rssFeedURL: URL, episodes: [Episode]) {
        self.id = id
        self.name = name
        self.rssFeedURL = rssFeedURL
        self.episodes = episodes
    }
}
