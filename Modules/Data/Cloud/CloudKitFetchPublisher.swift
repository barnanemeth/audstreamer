//
//  CloudKitFetchPublisher.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 26..
//

import Foundation
import CloudKit
import Combine

final class CloudKitFetchPublisher: Publisher {

    // MARK: Typealiases

    typealias Output = [CKRecord]
    typealias Failure = Error

    // MARK: Private properties

    private let database: CKDatabase
    private let recordType: String
    private let predicate: NSPredicate?
    private let sortDescriptors: [NSSortDescriptor]?

    // MARK: Init

    init(database: CKDatabase, recordType: String, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) {
        self.database = database
        self.recordType = recordType
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
    }

    // MARK: Publisher

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, [CKRecord] == S.Input {
        let subscription = CloudKitFetchSubscription(
            subscriber: subscriber,
            database: database,
            recordType: recordType,
            predicate: predicate,
            sortDescriptors: sortDescriptors
        )
        subscriber.receive(subscription: subscription)
    }
}

final private class CloudKitFetchSubscription<S: Subscriber> where S.Input == [CKRecord], S.Failure == Error {

    // MARK: Typealiases

    private typealias RecordMatchedBlock = ((CKRecord.ID, Result<CKRecord, Error>) -> Void)
    private typealias QueryResultBlock = ((Result<CKQueryOperation.Cursor?, Error>) -> Void)

    // MARK: Private properties

    private let subscriber: S
    private let database: CKDatabase
    private let recordType: String
    private let predicate: NSPredicate?
    private let sortDescriptors: [NSSortDescriptor]?

    private var cancellables = Set<AnyCancellable>()
    private let cursorSubject = PassthroughSubject<CKQueryOperation.Cursor?, Never>()
    private var currentOperation: Operation?

    private var records = [CKRecord]()

    private lazy var commonRecordMatchedBlock: RecordMatchedBlock = { [weak self] _, result in
        guard let record = try? result.get() else { return }
        self?.records.append(record)
    }
    private lazy var commonQueryResultBlock: QueryResultBlock = { [weak self] result in
        switch result {
        case let .success(cursor): self?.cursorSubject.send(cursor)
        case let .failure(error): self?.finish(with: error)
        }
    }
    private var operationConfig: CKOperation.Configuration {
        let config = CKOperation.Configuration()
        config.allowsCellularAccess = true
        config.qualityOfService = .userInitiated
        return config
    }

    // MARK: Init

    init(subscriber: S,
         database: CKDatabase,
         recordType: String,
         predicate: NSPredicate?,
         sortDescriptors: [NSSortDescriptor]?) {
        self.subscriber = subscriber
        self.database = database
        self.recordType = recordType
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors

        subscribeToCursor()
    }
}

// MARK: - Subscription

extension CloudKitFetchSubscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        startFetching()
    }

    func cancel() {
        currentOperation?.cancel()
    }
}

// MARK: - Helpers

extension CloudKitFetchSubscription {
    private func startFetching() {
        let query = CKQuery(recordType: recordType, predicate: predicate ?? NSPredicate(value: true))
        query.sortDescriptors = sortDescriptors
        let operation = CKQueryOperation(query: query)
        operation.configuration = operationConfig

        setupOperation(operation)
        currentOperation = operation
        database.add(operation)
    }

    private func subscribeToCursor() {
        cursorSubject
            .sink { [unowned self] cursor in
                if let cursor = cursor {
                    self.fetchNext(from: cursor)
                } else {
                    self.finish()
                }
            }
            .store(in: &cancellables)
    }

    private func fetchNext(from cursor: CKQueryOperation.Cursor) {
        let operation = CKQueryOperation(cursor: cursor)
        setupOperation(operation)
        currentOperation = operation
        database.add(operation)
    }

    private func setupOperation(_ operation: CKQueryOperation) {
        operation.resultsLimit = CKQueryOperation.maximumResults
        operation.recordMatchedBlock = commonRecordMatchedBlock
        operation.queryResultBlock = commonQueryResultBlock
    }

    private func finish(with error: Error? = nil) {
        if let error = error {
            subscriber.receive(completion: .failure(error))
        } else {
            _ = subscriber.receive(records)
            subscriber.receive(completion: .finished)
        }

        cancel()
    }
}
