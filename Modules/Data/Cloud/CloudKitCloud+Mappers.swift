//
//  CloudKitCloud+Mappers.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 27..
//

import Foundation
import CloudKit

import Domain

extension CloudKitCloud {
    func mapFavorites(_ records: [CKRecord]) -> [String] {
        records.compactMap { $0.value(forKey: Key.episodeIDKey) as? String }
    }

    func mapLastPlayedDates(_ records: [CKRecord]) -> [String: Date] {
        records.reduce(into: [String: Date](), { lastPlayedDates, record in
            guard let episodeID = record.object(forKey: Key.episodeIDKey) as? String,
                  let lastPlayedDate = record.object(forKey: Key.lastPlayedDateKey) as? Date else { return }
            lastPlayedDates[episodeID] = lastPlayedDate
        })
    }

    func mapLastPositions(_ records: [CKRecord]) -> [String: Int] {
        records.reduce(into: [String: Int](), { lastPositions, record in
            guard let episodeID = record.object(forKey: Key.episodeIDKey) as? String,
                  let lastPosition = record.object(forKey: Key.lastPositionKey) as? Int else { return }
            lastPositions[episodeID] = lastPosition
        })
    }

    func mapNumberOfPlays(_ records: [CKRecord]) -> [String: Int] {
        records.reduce(into: [String: Int](), { numberOfPlaysDictionary, record in
            guard let episodeID = record.object(forKey: Key.episodeIDKey) as? String,
                  let numberOfPlays = record.object(forKey: Key.numberOfPlaysKey) as? Int else { return }
            numberOfPlaysDictionary[episodeID] = numberOfPlays
        })
    }

    func mapUserRatings(_ records: [CKRecord]) -> [UserRating] {
        records.compactMap { record in
            guard let userID = record.value(forKey: Key.userIDKey) as? String,
                  let episodeID = record.value(forKey: Key.episodeIDKey) as? String,
                  let rating = record.value(forKey: Key.ratingKey) as? Double else { return nil }
            return UserRating(userID: userID, episodeID: episodeID, rating: rating)
        }
    }
}
