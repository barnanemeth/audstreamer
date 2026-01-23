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
    public var podcastTitle: String

    public var duration: Int
    public var isFavourite: Bool
    public var lastPosition: Int?
    public var lastPlayed: Date?
    public var isDownloaded: Bool
    public var numberOfPlays: Int
    public var isOnWatch: Bool

    // MARK: Init

    public init(id: String,
                title: String,
                publishDate: Date,
                descriptionText: String? = nil,
                mediaURL: URL,
                image: URL? = nil,
                thumbnail: URL? = nil,
                link: URL? = nil,
                podcastTitle: String,
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
        self.podcastTitle = podcastTitle
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

// MARK: - Coding keys

extension Episode {
    public enum CodingKeys: String, CodingKey {
        case id
        case title
        case publishDate
        case duration
        case lastPosition
        case podcastTitle
    }
}
