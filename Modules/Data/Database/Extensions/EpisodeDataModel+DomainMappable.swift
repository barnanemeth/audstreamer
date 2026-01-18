//
//  EpisodeDataModel+DomainMappable.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import Domain

// MARK: - DomainMappable

extension EpisodeDataModel: DomainMappable {
    var asDomainModel: Episode? {
        Episode(
            id: id,
            title: title,
            publishDate: publishDate,
            descriptionText: descriptionText,
            mediaURL: mediaURL,
            image: image,
            thumbnail: thumbnail,
            link: link,
            duration: duration ?? .zero,
            isFavourite: isFavourite,
            lastPosition: lastPosition,
            lastPlayed: lastPlayed,
            isDownloaded: isDownloaded,
            numberOfPlays: numberOfPlays,
            isOnWatch: isOnWatch
        )
    }
}
