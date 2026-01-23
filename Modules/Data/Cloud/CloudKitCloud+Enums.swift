//
//  CloudKitCloud+Enums.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 27..
//

import Foundation

extension CloudKitCloud {
    enum RecordType: String, CaseIterable {
        case favoriteRecordType = "EpisodeFavorite"
        case lastPlayedDateRecordType = "EpisodeLastPlayedDate"
        case lastPositionRecordType = "EpisodeLastPosition"
        case numberOfPlaysRecordType = "EpisodeNumberOfPlays"
        case podcastSubscriptionRecordType = "PodcastSubscription"

        var isPrivate: Bool { true }
    }

    enum Key {
        static let episodeIDKey = "episodeID"
        static let isFavoriteKey = "isFavorite"
        static let lastPlayedDateKey = "lastPlayedDate"
        static let lastPositionKey = "lastPosition"
        static let numberOfPlaysKey = "numberOfPlays"
        static let userIDKey = "userID"
        static let ratingKey = "rating"
        static let podcastIDKey = "podcastID"
        static let rssFeedKey = "rssFeed"
        static let isPrivate = "isPrivate"
        static let isSubscribed = "isSubscribed"
    }
}
