//
//  Episode.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 26..
//

import Foundation

public struct Episode: Identifiable, Hashable, Equatable {

    // MARK: Properties

    public let id: String
    public let title: String
    public let publishDate: Date
    public let descriptionText: String?
    public let mediaURL: URL
    public let image: URL?
    public let thumbnail: URL?
    public let link: URL?
    public let duration: Int
    public let isFavourite: Bool
    public let lastPosition: Int?
    public let lastPlayed: Date?
    public let isDownloaded: Bool
    public let numberOfPlays: Int
    public let isOnWatch: Bool

    // MARK: Init

    public init(id: String,
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
                isOnWatch: Bool = false) {
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
    public var url: URL {
        if isDownloaded, let localURL = possibleLocalURL {
            localURL
        } else {
            mediaURL
        }
    }
    public var preferredStartTime: Second? {
        guard let lastPosition else { return nil }
        return lastPosition > .zero && lastPosition != duration ? Second(lastPosition) : nil
    }
}

// MARK: - NowPlayable

extension Episode: NowPlayable {
    public var imageURL: URL? {
        // TODO: percent encoding?
        image
    }
}

// MARK: - Downloadable

extension Episode: Downloadable {
    public var remoteURL: URL {
        mediaURL
    }

    public var userInfo: [String: Any]? { nil }
}
