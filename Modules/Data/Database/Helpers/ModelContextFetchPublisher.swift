//
//  ModelContextFetchPublisher.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 05..
//

import Foundation
import Combine
import SwiftData

import Common

final class ModelContextFetchPublisher<DataModel: PersistentModel>: Publisher {

    // MARK: Typealiases

    typealias Output = [DataModel]
    typealias Failure = Error


    // MARK: Private properties

    private let contextManager: SwiftDataContextManager
    private let descriptor: FetchDescriptor<DataModel>

    private var task: Task<Void, Never>?

    // MARK: Init

    init(contextManager: SwiftDataContextManager, descriptor: FetchDescriptor<DataModel>) {
        self.contextManager = contextManager
        self.descriptor = descriptor
    }

    // MARK: Publisher

    func receive<S>(subscriber: S) where S: Subscriber, any Failure == S.Failure, [DataModel] == S.Input {
        let subscription = ModelContextFetchSubscription(
            subscriber: subscriber,
            contextManager: contextManager,
            descriptor: descriptor
        )
        subscriber.receive(subscription: subscription)
    }
}

// MARK: - ModelContextFetchSubscription

final fileprivate class ModelContextFetchSubscription<DataModel: PersistentModel, S: Subscriber> where S.Input == [DataModel], S.Failure == Error {

    // MARK: Private properties

    private let subscriber: S
    private let contextManager: SwiftDataContextManager
    private let descriptor: FetchDescriptor<DataModel>

    private var subscription: AnyCancellable?

    // MARK: Init

    init(subscriber: S, contextManager: SwiftDataContextManager, descriptor: FetchDescriptor<DataModel>) {
        self.subscriber = subscriber
        self.contextManager = contextManager
        self.descriptor = descriptor
    }
}

// MARK: - ModelContextFetchSubscriber + Subscription

extension ModelContextFetchSubscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        // TODO: filter duplications

        subscription = NotificationCenter.default.publisher(for: ModelContext.didSave)
            .toVoid()
            .prepend(())
            .asyncTryMap { [unowned self] in
                let models = try await contextManager.fetch(descriptor)
                let filtered = models.filter { !$0.hasChanges && !$0.isDeleted }
                return filtered
            }
            .sink(
                receiveCompletion: { [unowned self] completion in
                    switch completion {
                    case .finished: subscriber.receive(completion: .finished)
                    case let .failure(error): subscriber.receive(completion: .failure(error))
                    }
                },
                receiveValue: { [unowned self] output in
                    _ = subscriber.receive(output)
                }
            )
    }
    
    func cancel() {
        subscription?.cancel()
    }
}
