//
//  PodcastDataModel+Extensions.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import Foundation

import Domain

// MARK: - DomainMappable

extension PodcastDataModel: DomainMappable {
    var asDomainModel: Podcast? {
        Podcast(
            id: id,
            title: title,
            description: descriptionText,
            author: author,
            language: language,
            isExplicit: isExplicit,
            rssFeedURL: rssURL,
            imageURL: imageURL,
            linkURL: linkURL,
            isSubscribed: true,
            isPrivate: isPrivate
        )
    }
}
