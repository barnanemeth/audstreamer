//
//  PodcastDataModel+DomainMappable.swift
//  Domain
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import Foundation

import Domain

// MARK: - DomainMappable

extension PodcastDataModel: DomainMappable {
    var asDomainModel: Podcast? {
        Podcast(id: id, name: name, rssFeedURL: rssLink, episodes: episodes.asDomainModels)
    }
}
