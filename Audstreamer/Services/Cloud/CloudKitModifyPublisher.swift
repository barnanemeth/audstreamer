//
//  CloudKitModifyPublisher.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 26..
//

import Foundation
import CloudKit
import Combine

final class CloudKitModifyPublisher: Publisher {

    // MARK: Typealiases

    typealias Output = Void
    typealias Failure = Error

    enum ModifyType {
        case save
        case delete
    }

    // MARK: Private properties

    private let database: CKDatabase
    private let records: [CKRecord]
    private let type: ModifyType

    // MARK: Init

    init(database: CKDatabase, records: [CKRecord], type: ModifyType) {
        self.database = database
        self.records = records
        self.type = type
    }

    // MARK: Publisher

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Void == S.Input {
        let subscription = CloudKitModifySubscription(
            subscriber: subscriber,
            database: database,
            records: records,
            type: type
        )
        subscriber.receive(subscription: subscription)
    }
}

final private class CloudKitModifySubscription<S: Subscriber> where S.Input == Void, S.Failure == Error {

    // MARK: Private properties

    private let subscriber: S
    private let database: CKDatabase
    private let records: [CKRecord]
    private let type: CloudKitModifyPublisher.ModifyType

    private var cancellables = Set<AnyCancellable>()

    @Published private var operations = Set<Operation>()

    private var operationConfig: CKOperation.Configuration {
        let config = CKOperation.Configuration()
        config.allowsCellularAccess = true
        config.qualityOfService = .userInitiated
        return config
    }

    // MARK: Init

    init(subscriber: S, database: CKDatabase, records: [CKRecord], type: CloudKitModifyPublisher.ModifyType) {
        self.subscriber = subscriber
        self.database = database
        self.records = records
        self.type = type

        subscribeToOperations()
    }
}

// MARK: - Subscription

extension CloudKitModifySubscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        guard !records.isEmpty else { return finish() }
        addOperations()
    }

    func cancel() {
        operations.forEach { $0.cancel() }
    }
}

// MARK: - Helpers

extension CloudKitModifySubscription {
    private func sliceRecords(_ records: [CKRecord]) -> [[CKRecord]] {
        records.reduce(into: [[CKRecord]](), { records, record in
            guard !records.isEmpty else { return records.append([record]) }
            if records[records.count - 1].count < 400 {
                records[records.count - 1].append(record)
            } else {
                records.append([record])
            }
        })
    }

    private func addOperations() {
        sliceRecords(records)
            .map { records in
                let operation = CKModifyRecordsOperation()
                operation.configuration = operationConfig
                switch type {
                case .save: operation.recordsToSave = records
                case .delete: operation.recordIDsToDelete = records.map(\.recordID)
                }
                operation.modifyRecordsResultBlock = { [weak self] result in
                    switch result {
                    case .success: self?.operations.remove(operation)
                    case let .failure(error): self?.finish(with: error)
                    }
                }
                return operation
            }
            .forEach { operation in
                operations.insert(operation)
                database.add(operation)
            }
    }

    private func subscribeToOperations() {
        $operations
            .removeDuplicates()
            .drop(while: { $0.isEmpty })
            .first { $0.isEmpty }
            .toVoid()
            .sink { [unowned self] _ in self.finish() }
            .store(in: &cancellables)
    }

    private func finish(with error: Error? = nil) {
        if let error = error {
            subscriber.receive(completion: .failure(error))
        } else {
            _ = subscriber.receive(())
            subscriber.receive(completion: .finished)
        }

        cancel()
    }
}
