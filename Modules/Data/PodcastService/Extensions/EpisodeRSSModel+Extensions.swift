//
//  EpisodeRSSModel+Extensions.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 21..
//

import Foundation

import Domain

internal import FeedKit
internal import XMLKit

// MARK: - Domain mappable

extension EpisodeRSSModel {
    func asDomainModel(podcastTitle: String) -> Episode? {
        guard let id = guid?.text, let mappedTitle, let pubDate, let mappedMediaURL, let mappedDuration else { return nil }
        return Episode(
            id: id,
            title: mappedTitle,
            publishDate: pubDate,
            descriptionText: description ?? iTunes?.subtitle,
            mediaURL: mappedMediaURL,
            image: mappedImage,
            thumbnail: mappedImage,
            link: mappedLink,
            podcastTitle: podcastTitle,
            duration: mappedDuration,
            isFavourite: false,
            lastPosition: nil,
            lastPlayed: nil,
            isDownloaded: false,
            numberOfPlays: .zero,
            isOnWatch: false
        )
    }
}

// MARK: - Data mappable

extension EpisodeRSSModel: DataMappable {
    var asDataModel: EpisodeDataModel? {
        guard let id = guid?.text, let mappedTitle, let pubDate, let mappedMediaURL else { return nil }
        return EpisodeDataModel(
            id: id,
            title: mappedTitle,
            publishDate: pubDate,
            descriptionText: description ?? iTunes?.subtitle,
            mediaURL: mappedMediaURL,
            image: mappedImage,
            thumbnail: mappedImage,
            link: mappedLink,
            duration: mappedDuration,
            isFavourite: false,
            lastPosition: nil,
            lastPlayed: nil,
            isDownloaded: false,
            numberOfPlays: .zero,
            isOnWatch: false
        )
    }
}

// MARK: - Helpers

fileprivate extension EpisodeRSSModel {
    var mappedTitle: String? {
        title ?? iTunes?.title
    }

    var mappedMediaURL: URL? {
        guard let urlString = enclosure?.attributes?.url, let url = URL(string: urlString) else { return nil }
        return url
    }

    var mappedImage: URL? {
        guard let urlString = iTunes?.image?.attributes?.href, let url = URL(string: urlString) else { return nil }
        return url
    }

    var mappedLink: URL? {
        guard let urlString = link, let url = URL(string: urlString) else { return nil }
        return url
    }

    var mappedDuration: Int? {
        guard let duration = iTunes?.duration else { return nil }
        return Int(duration)
    }
}
