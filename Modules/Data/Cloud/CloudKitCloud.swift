//
//  CloudKitCloud.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 31..
//

import Foundation
import Combine
import CloudKit

import Common
import Domain

final class CloudKitCloud {

    // MARK: Constants

    private enum DatabaseType {
        case `private`
        case `public`
    }

    private enum Constant {
        static let defaultQueue = DispatchQueue.main
        static let containerIdentifier = "iCloud.com.barnanemeth.audstreamer"
        static let updateThrottleInterval: DispatchQueue.SchedulerTimeType.Stride = .seconds(60)
    }

    // MARK: Dependencies

    @Injected private var database: Database
    @Injected private var secureStore: SecureStore

    // MARK: Properties

    @Published var favoritesChanges = [String: Bool]()
    @Published var lastPlayedDatesChanges = [String: Date]()
    @Published var lastPositionsChanges = [String: Int]()
    @Published var numberOfPlaysChanges = [String: Int]()

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private let container = CKContainer(identifier: Constant.containerIdentifier)
    private lazy var privateDatabase = container.privateCloudDatabase
    private lazy var publicDatabase = container.publicCloudDatabase
    private lazy var userID: String? = {
        do {
            let token = try secureStore.getToken()
            return try JWTHelper.getSubject(from: token)
        } catch {
            return nil
        }
    }()

    // MARK: Init

    init() {
        subscribeToChanges()

        uploadUserRatingsIfPossible().sink().store(in: &cancellables)
    }
}

// MARK: - Cloud

extension CloudKitCloud: Cloud {
    func getFavoriteEpisodeIDs() -> AnyPublisher<[String], Error> {
        let predicate = NSPredicate(format: "\(Key.isFavoriteKey) == TRUE")
        return fetchData(recordType: .favoriteRecordType, predicate: predicate)
            .map { [unowned self] in self.mapFavorites($0) }
            .catch { [unowned self] in self.handleError($0) }
            .receive(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func setFavorite(_ isFavorite: Bool, for episodeID: String) -> AnyPublisher<Void, Error> {
        Just(favoritesChanges[episodeID] = isFavorite)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getLastPlayedDates() -> AnyPublisher<[String: Date], Error> {
        fetchData(recordType: .lastPlayedDateRecordType)
            .map { [unowned self] in self.mapLastPlayedDates($0) }
            .catch { [unowned self] in self.handleError($0) }
            .receive(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func setLastPlayedDate(_ lastPlayedDate: Date, for episodeID: String) -> AnyPublisher<Void, Error> {
        Just(lastPlayedDatesChanges[episodeID] = lastPlayedDate)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getLastPositions() -> AnyPublisher<[String: Int], Error> {
        fetchData(recordType: .lastPositionRecordType)
            .map { [unowned self] in self.mapLastPositions($0) }
            .catch { [unowned self] in self.handleError($0) }
            .receive(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func setLastPosition(_ lastPosition: Int, for episodeID: String) -> AnyPublisher<Void, Error> {
        Just(lastPositionsChanges[episodeID] = lastPosition)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getNumberOfPlays() -> AnyPublisher<[String: Int], Error> {
        fetchData(recordType: .numberOfPlaysRecordType)
            .map { [unowned self] in self.mapNumberOfPlays($0) }
            .catch { [unowned self] in self.handleError($0) }
            .receive(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func setNumberOfPlays(_ numberOfPlays: Int, for episodeID: String) -> AnyPublisher<Void, Error> {
        Just(numberOfPlaysChanges[episodeID] = numberOfPlays)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getUserRatings() -> AnyPublisher<[UserRating], Error> {
        fetchData(recordType: .userRating)
            .map { [unowned self] in self.mapUserRatings($0) }
            .eraseToAnyPublisher()
    }

    func synchronizePrivateData() -> AnyPublisher<Void, Error> {
        RecordType.allCases
            .filter { $0.isPrivate }
            .map { recordsToSave(for: $0) }
            .zip()
            .map { $0.flatMap { $0 } }
            .flatMap { [unowned self] in self.modifyRecords($0, databaseType: .private) }
            .catch { [unowned self] in self.handleError($0) }
            .eraseToAnyPublisher()
    }

    func synchronizePublicData() -> AnyPublisher<Void, Error> {
        uploadUserRatingsIfPossible()
    }

    func resetPrivateData() -> AnyPublisher<Void, Error> {
        RecordType.allCases.map { fetchData(recordType: $0) }
            .zip()
            .map { $0.flatMap { $0 } }
            .flatMap { [unowned self] in self.deleteRecords($0, databaseType: .private) }
            .handleEvents(receiveCompletion: { [unowned self] completion in
                guard case .finished = completion else { return }
                self.resetChanges()
            })
            .catch { [unowned self] in self.handleError($0) }
            .eraseToAnyPublisher()
    }

    func resetPublicData() -> AnyPublisher<Void, Error> {
        deleteUserRatingsIfPossible()
    }

    func updateFromLocal() -> AnyPublisher<Void, Error> {
        Publishers.Zip(resetPrivateData(), database.getEpisodes().first())
            .receive(on: DispatchQueue.main)
            .map { _, episodes -> [CKRecord] in
                let favorites = episodes.filter { $0.isFavourite }.map { episode in
                    let record = CKRecord(recordType: RecordType.favoriteRecordType.rawValue)
                    record.setValue(episode.id, forKey: Key.episodeIDKey)
                    record.setValue(episode.isFavourite ? 1 : 0, forKey: Key.isFavoriteKey)
                    return record
                }
                let lastPlayedDates = episodes.filter { $0.lastPlayed != nil }.map { episode in
                    let record = CKRecord(recordType: RecordType.lastPlayedDateRecordType.rawValue)
                    record.setValue(episode.id, forKey: Key.episodeIDKey)
                    record.setValue(episode.lastPlayed, forKey: Key.lastPlayedDateKey)
                    return record
                }
                let lastPositions = episodes.filter { $0.lastPosition ?? -1 > .zero }.map { episode in
                    let record = CKRecord(recordType: RecordType.lastPositionRecordType.rawValue)
                    record.setValue(episode.id, forKey: Key.episodeIDKey)
                    record.setValue(episode.lastPosition, forKey: Key.lastPositionKey)
                    return record
                }
                let numberOfPlays = episodes.filter { $0.numberOfPlays > .zero }.map { episode in
                    let record = CKRecord(recordType: RecordType.numberOfPlaysRecordType.rawValue)
                    record.setValue(episode.id, forKey: Key.episodeIDKey)
                    record.setValue(episode.numberOfPlays, forKey: Key.numberOfPlaysKey)
                    return record
                }

                return favorites + lastPlayedDates + lastPositions + numberOfPlays
            }
            .flatMap { [unowned self] in self.modifyRecords($0, databaseType: .private) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension CloudKitCloud {
    func fetchData(recordType: RecordType,
                   predicate: NSPredicate? = nil,
                   sortDescriptors: [NSSortDescriptor]? = nil) -> AnyPublisher<[CKRecord], Error> {
        let fetchPublisher = CloudKitFetchPublisher(
            database: database(for: recordType),
            recordType: recordType.rawValue,
            predicate: predicate,
            sortDescriptors: sortDescriptors
        )
        return fetchPublisher.eraseToAnyPublisher()
    }

    func updateNeeded(for recordType: RecordType) -> Bool {
        switch recordType {
        case .favoriteRecordType: return !favoritesChanges.isEmpty
        case .lastPlayedDateRecordType: return !lastPlayedDatesChanges.isEmpty
        case .lastPositionRecordType: return !lastPositionsChanges.isEmpty
        case .numberOfPlaysRecordType: return !numberOfPlaysChanges.isEmpty
        case .userRating: return false
        }
    }

    private func uploadUserRatingsIfPossible() -> AnyPublisher<Void, Error> {
        guard let userID = userID else { return Just.void() }
        return RatingHelper.getEpisodeRatings()
            .flatMap { [unowned self] ratings -> AnyPublisher<([CKRecord], [RatingData]), Error> in
                let predicate = NSPredicate(format: "\(Key.userIDKey) == %@", userID)
                let records = self.fetchData(recordType: .userRating, predicate: predicate)

                let ratingsPublisher = Just(ratings).setFailureType(to: Error.self)

                return Publishers.Zip(records, ratingsPublisher).eraseToAnyPublisher()
            }
            .map { records, ratings in
                ratings.reduce(into: [CKRecord](), { recordsToSave, rating in
                    let record = records.first(where: { record in
                        (record.value(forKey: Key.episodeIDKey) as? String) == rating.episodeID
                    })

                    if let record = record {
                        let recordRating = record.object(forKey: Key.ratingKey) as? Double
                        if recordRating != rating.rating {
                            record.setValue(rating.rating, forKey: Key.ratingKey)
                            recordsToSave.append(record)
                        }
                    } else {
                        let record = CKRecord(recordType: RecordType.userRating.rawValue)
                        record.setValue(userID, forKey: Key.userIDKey)
                        record.setValue(rating.episodeID, forKey: Key.episodeIDKey)
                        record.setValue(rating.rating, forKey: Key.ratingKey)
                        recordsToSave.append(record)
                    }
                })
            }
            .flatMap { [unowned self] in self.modifyRecords($0, databaseType: .public) }
            .eraseToAnyPublisher()
    }

    private func deleteUserRatingsIfPossible() -> AnyPublisher<Void, Error> {
        guard let userID = userID else { return Just.void() }

        let predicate = NSPredicate(format: "\(Key.userIDKey) == %@", userID)
        return fetchData(recordType: .userRating, predicate: predicate)
            .flatMap { [unowned self] in self.deleteRecords($0, databaseType: .public) }
            .eraseToAnyPublisher()
    }

    private func modifyRecords(_ records: [CKRecord], databaseType: DatabaseType) -> AnyPublisher<Void, Error> {
        let modifyPublisher = CloudKitModifyPublisher(
            database: database(for: databaseType),
            records: records,
            type: .save
        )
        return modifyPublisher
            .handleEvents(receiveCompletion: { [unowned self] completion in
                guard case .finished = completion else { return }
                self.resetChanges()
            })
            .eraseToAnyPublisher()
    }

    private func deleteRecords(_ records: [CKRecord], databaseType: DatabaseType) -> AnyPublisher<Void, Error> {
        let modifyPublisher = CloudKitModifyPublisher(
            database: database(for: databaseType),
            records: records,
            type: .delete
        )
        return modifyPublisher.eraseToAnyPublisher()
    }

    private func resetChanges() {
        favoritesChanges.removeAll()
        lastPlayedDatesChanges.removeAll()
        lastPositionsChanges.removeAll()
        numberOfPlaysChanges.removeAll()
    }

    private func handleError<Output>(_ error: Error) -> AnyPublisher<Output, Error> {
        if let cloudKitError = error as? CKError {
            switch cloudKitError.code {
            case .accountTemporarilyUnavailable: return Fail(error: CloudError.unavailableAccount).eraseToAnyPublisher()
            case .notAuthenticated: return Fail(error: CloudError.unavailableAccount).eraseToAnyPublisher()
            default: return Fail(error: CloudError.generalError(error)).eraseToAnyPublisher()
            }
        }
        return Fail(error: CloudError.generalError(error)).eraseToAnyPublisher()
    }

    private func subscribeToChanges() {
        let favoriteChanges = $favoritesChanges.filter { !$0.isEmpty }.toVoid()
        let lastPlayedDatesChanges = $lastPlayedDatesChanges.filter { !$0.isEmpty }.toVoid()
        let lastPositionsChanges = $lastPositionsChanges.filter { !$0.isEmpty }.toVoid()
        let numberOfPlaysChanges = $numberOfPlaysChanges.filter { !$0.isEmpty }.toVoid()

        Publishers.Merge4(favoriteChanges, lastPlayedDatesChanges, lastPositionsChanges, numberOfPlaysChanges)
            .throttle(for: Constant.updateThrottleInterval, scheduler: Constant.defaultQueue, latest: true)
            .flatMap { [unowned self] in self.synchronizePrivateData().catch { _ in Just.void() } }
            .sink()
            .store(in: &cancellables)
    }

    private func database(for recordType: RecordType) -> CKDatabase {
        switch recordType {
        case .userRating:
            return publicDatabase
        case .favoriteRecordType, .lastPlayedDateRecordType, .lastPositionRecordType, .numberOfPlaysRecordType:
            return privateDatabase
        }
    }

    private func database(for databaseType: DatabaseType) -> CKDatabase {
        switch databaseType {
        case .private: return privateDatabase
        case .public: return publicDatabase
        }
    }
}
