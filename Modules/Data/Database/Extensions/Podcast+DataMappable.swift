//
//  Podcast+DataMappable.swift
//  Domain
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import Domain

// MARK: - DataMappable

extension Podcast: DataMappable {
    var asDataModel: PodcastDataModel? {
        PodcastDataModel(
            id: id,
            name: name,
            rssLink: rssFeedURL,
            episodes: episodes.asDomainModels
        )
    }
}
