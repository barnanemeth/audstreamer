//
//  PodcastDataModel.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import Foundation
import SwiftData

@Model
final class PodcastDataModel {
    @Attribute(.unique) var id: String
    var name: String
    var rssLink: URL
    @Relationship(deleteRule: .cascade) var episodes = [EpisodeDataModel]()

    init(id: String, name: String, rssLink: URL, episodes: [EpisodeDataModel]) {
        self.id = id
        self.name = name
        self.rssLink = rssLink
        self.episodes = episodes
    }
}
