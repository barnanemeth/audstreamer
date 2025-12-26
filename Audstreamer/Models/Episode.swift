//
//  Episode.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 26..
//

import Foundation

struct Episode: Identifiable, Hashable, Equatable {

    // MARK: Properties

    let id: String
    let title: String
    let publishDate: Date
    let descriptionText: String?
    let mediaURL: URL
    let image: URL?
    let thumbnail: URL?
    let link: URL?
    let duration: Int
    let isFavourite: Bool
    let lastPosition: Int?
    let lastPlayed: Date?
    let isDownloaded: Bool
    let numberOfPlays: Int
    let isOnWatch: Bool

    // MARK: Init

    init(id: String,
         title: String,
         publishDate: Date,
         descriptionText: String?,
         mediaURL: URL,
         image: URL?,
         thumbnail: URL?,
         link: URL?,
         duration: Int,
         isFavourite: Bool = false,
         lastPosition: Int? = nil,
         lastPlayed: Date? = nil,
         isDownloaded: Bool = false,
         numberOfPlays: Int = .zero,
         isOnWatch: Bool = false
    ) {
        self.id = id
        self.title = title
        self.publishDate = publishDate
        self.descriptionText = descriptionText
        self.mediaURL = mediaURL
        self.image = image
        self.thumbnail = thumbnail
        self.link = link
        self.duration = duration
        self.isFavourite = isFavourite
        self.lastPosition = lastPosition
        self.lastPlayed = lastPlayed
        self.isDownloaded = isDownloaded
        self.numberOfPlays = numberOfPlays
        self.isOnWatch = isOnWatch
    }
}

// MARK: - AudioPlayable

extension Episode: AudioPlayable {
    var url: URL {
        if isDownloaded, let localURL = possibleLocalURL {
            localURL
        } else {
            mediaURL
        }
    }
    var preferredStartTime: Second? {
        guard let lastPosition else { return nil }
        return lastPosition > .zero && lastPosition != duration ? Second(lastPosition) : nil
    }
}

// MARK: - NowPlayable

extension Episode: NowPlayable {
    var imageURL: URL? {
        // TODO: percent encoding?
        image
    }
}

// MARK: - Downloadable

extension Episode: Downloadable {
    var remoteURL: URL {
        mediaURL
    }

    var userInfo: [String: Any]? { nil }
}
