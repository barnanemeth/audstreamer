//
//  PodcastRSSModel+Extensions.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 21..
//

import Foundation

import Domain

internal import FeedKit
internal import XMLKit

// MARK: - Domain mappable

extension PodcastRSSModel {
    func asDomainModel(id: String, rssFeedURL: URL) -> Podcast? {
        guard let mappedTitle else { return nil }
        return Podcast(
            id: id,
            title: mappedTitle,
            description: description ?? iTunes?.subtitle,
            author: iTunes?.author,
            language: language,
            isExplicit: mappedExplicit,
            rssFeedURL: rssFeedURL,
            imageURL: mappedImage,
            linkURL: mappedLink,
            isSubscribed: false,
            isPrivate: false
        )
    }
}

// MARK: - Data mappable

extension PodcastRSSModel {
    func asDataModel(id: String, rssFeedURL: URL, isPrivate: Bool) -> PodcastDataModel?  {
        guard let mappedTitle, let items else { return nil }
        return PodcastDataModel(
            id: id,
            title: mappedTitle,
            descriptionText: description ?? iTunes?.subtitle,
            author: iTunes?.author,
            language: language,
            isExplicit: mappedExplicit,
            rssURL: rssFeedURL,
            imageURL: mappedImage,
            linkURL: mappedLink,
            isPrivate: isPrivate,
            episodes: items.compactMap { $0.asDataModel }
        )
    }
}

// MARK: - Helpers

fileprivate extension PodcastRSSModel {
    var mappedTitle: String? {
        title ?? iTunes?.title
    }

    var mappedExplicit: Bool? {
        guard let explicitField = iTunes?.explicit?.lowercased() else { return nil }

        let trueRegex = /(yes|explicit|true)/.ignoresCase()
        let falseRegex = /()/

        return if (try? trueRegex.wholeMatch(in: explicitField)) != nil {
            true
        } else if (try? falseRegex.wholeMatch(in: explicitField)) != nil {
            false
        } else {
            nil
        }
    }

    var mappedImage: URL? {
        guard let urlString = image?.url ?? iTunes?.image?.attributes?.href else { return nil }
        return URL(string: urlString)
    }

    var mappedLink: URL? {
        guard let link else { return nil }
        return URL(string: link)
    }
}
