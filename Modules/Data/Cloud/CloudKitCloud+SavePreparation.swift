//
//  CloudKitCloud+SavePreparation.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 27..
//

import Foundation
import CloudKit
import Combine

extension CloudKitCloud {
    func recordsToSave(for recordType: RecordType) -> AnyPublisher<[CKRecord], Error> {
        guard updateNeeded(for: recordType) else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        let sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        return fetchData(recordType: recordType, sortDescriptors: sortDescriptors)
            .map { [unowned self] records in
                switch recordType {
                case .favoriteRecordType: return self.favoriteRecordsToSave(from: records)
                case .lastPlayedDateRecordType: return self.lastPlayedDateRecordsToSave(from: records)
                case .lastPositionRecordType: return self.lastPositionRecordsToSave(from: records)
                case .numberOfPlaysRecordType: return self.numberOfPlaysRecordsToSave(from: records)
                case .podcastSubscriptionRecordType: return self.subscribedPodcastRecordsToSave(from: records)
                }
            }
            .eraseToAnyPublisher()
    }

    private func favoriteRecordsToSave(from records: [CKRecord]) -> [CKRecord] {
        favoritesChanges.reduce(into: [CKRecord](), { recordsToSave, item in
            let episodeID = item.key
            let isFavorite = item.value

            let recordToUpdate = records.first { ($0.value(forKey: Key.episodeIDKey) as? String) == episodeID }
            if let recordToUpdate = recordToUpdate {
                recordToUpdate.setValue(isFavorite ? 1 : 0, forKey: Key.isFavoriteKey)
                recordsToSave.append(recordToUpdate)
            } else {
                let record = CKRecord(recordType: RecordType.favoriteRecordType.rawValue)
                record.setValue(episodeID, forKey: Key.episodeIDKey)
                record.setValue(isFavorite ? 1 : 0, forKey: Key.isFavoriteKey)
                recordsToSave.append(record)
            }
        })
    }

    private func lastPlayedDateRecordsToSave(from records: [CKRecord]) -> [CKRecord] {
        lastPlayedDatesChanges.reduce(into: [CKRecord](), { recordsToSave, item in
            let episodeID = item.key
            let lastPlayedDate = item.value

            let recordToUpdate = records.first { ($0.value(forKey: Key.episodeIDKey) as? String) == episodeID }
            if let recordToUpdate = recordToUpdate {
                recordToUpdate.setValue(lastPlayedDate, forKey: Key.lastPlayedDateKey)
                recordsToSave.append(recordToUpdate)
            } else {
                let record = CKRecord(recordType: RecordType.lastPlayedDateRecordType.rawValue)
                record.setValue(episodeID, forKey: Key.episodeIDKey)
                record.setValue(lastPlayedDate, forKey: Key.lastPlayedDateKey)
                recordsToSave.append(record)
            }
        })
    }

    private func lastPositionRecordsToSave(from records: [CKRecord]) -> [CKRecord] {
        lastPositionsChanges.reduce(into: [CKRecord](), { recordsToSave, item in
            let episodeID = item.key
            let lastPosition = item.value

            let recordToUpdate = records.first { ($0.value(forKey: Key.episodeIDKey) as? String) == episodeID }
            if let recordToUpdate = recordToUpdate {
                recordToUpdate.setValue(lastPosition, forKey: Key.lastPositionKey)
                recordsToSave.append(recordToUpdate)
            } else {
                let record = CKRecord(recordType: RecordType.lastPositionRecordType.rawValue)
                record.setValue(episodeID, forKey: Key.episodeIDKey)
                record.setValue(lastPosition, forKey: Key.lastPositionKey)
                recordsToSave.append(record)
            }
        })
    }

    func numberOfPlaysRecordsToSave(from records: [CKRecord]) -> [CKRecord] {
        numberOfPlaysChanges.reduce(into: [CKRecord](), { recordsToSave, item in
            let episodeID = item.key
            let numberOfPlays = item.value

            let recordToUpdate = records.first { ($0.value(forKey: Key.episodeIDKey) as? String) == episodeID }
            if let recordToUpdate = recordToUpdate {
                recordToUpdate.setValue(numberOfPlays, forKey: Key.numberOfPlaysKey)
                recordsToSave.append(recordToUpdate)
            } else {
                let record = CKRecord(recordType: RecordType.numberOfPlaysRecordType.rawValue)
                record.setValue(episodeID, forKey: Key.episodeIDKey)
                record.setValue(numberOfPlays, forKey: Key.numberOfPlaysKey)
                recordsToSave.append(record)
            }
        })
    }

    func subscribedPodcastRecordsToSave(from records: [CKRecord]) -> [CKRecord] {
        podcastSubscriptionChanges.reduce(into: [CKRecord](), { recordsToSave, item in
            let podcastID = item.key
            let feedURL = item.value.feedURL
            let isPrivate = item.value.isPrivate
            let isSubscribed = item.value.isSubscribed

            let recordToUpdate = records.first { ($0.value(forKey: Key.podcastIDKey) as? String) == podcastID }
            if let recordToUpdate = recordToUpdate {
                recordToUpdate.setValue(isSubscribed ? 1 : 0, forKey: Key.isSubscribed)
                recordsToSave.append(recordToUpdate)
            } else {
                let record = CKRecord(recordType: RecordType.podcastSubscriptionRecordType.rawValue)
                record.setValue(podcastID, forKey: Key.podcastIDKey)
                record.setValue(feedURL.absoluteString, forKey: Key.rssFeedKey)
                record.setValue(isPrivate ? 1 : 0, forKey: Key.isPrivate)
                record.setValue(isSubscribed ? 1 : 0, forKey: Key.isSubscribed)
                recordsToSave.append(record)
            }
        })
    }
}
