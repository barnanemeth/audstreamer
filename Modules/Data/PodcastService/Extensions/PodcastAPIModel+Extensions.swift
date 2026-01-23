//
//  PodcastAPIModel+Extensions.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 21..
//

import Foundation

import Domain

internal import AudstreamerAPIClient

// MARK: - DomainMappable

extension PodcastAPIModel: DomainMappable {
    var asDomainModel: Podcast? {
        guard let rssURL = URL(string: rss) else { return nil }
        return Podcast(
            id: id,
            title: title,
            description: description,
            author: author,
            language: language,
            isExplicit: isExplicit,
            rssFeedURL: rssURL,
            imageURL: {
                if let urlString = image, let url = URL(string: urlString) {
                    url
                } else {
                    nil
                }
            }(),
            linkURL: {
                if let urlString = link, let url = URL(string: urlString) {
                    url
                } else {
                    nil
                }
            }(),
            isSubscribed: false,
            isPrivate: false
        )
    }
}
