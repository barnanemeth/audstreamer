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
        case userRating = "UserRating"

        var isPrivate: Bool {
            switch self {
            case .userRating: return false
            default: return true
            }
        }
    }

    enum Key {
        static let episodeIDKey = "episodeID"
        static let isFavoriteKey = "isFavorite"
        static let lastPlayedDateKey = "lastPlayedDate"
        static let lastPositionKey = "lastPosition"
        static let numberOfPlaysKey = "numberOfPlays"
        static let userIDKey = "userID"
        static let ratingKey = "rating"
    }
}
