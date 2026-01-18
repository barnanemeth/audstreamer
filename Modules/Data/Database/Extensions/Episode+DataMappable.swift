//
//  Episode+DataMappable.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import Domain

// MARK: - DataMappable

extension Episode: DataMappable {
    var asDataModel: EpisodeDataModel? {
        EpisodeDataModel(
            id: id,
            title: title,
            publishDate: publishDate,
            descriptionText: descriptionText,
            mediaURL: mediaURL,
            image: image,
            thumbnail: thumbnail,
            link: link,
            duration: duration,
            isFavourite: isFavourite,
            lastPosition: lastPosition,
            lastPlayed: lastPlayed,
            isDownloaded: isDownloaded,
            numberOfPlays: numberOfPlays,
            isOnWatch: isOnWatch
        )
    }
}
