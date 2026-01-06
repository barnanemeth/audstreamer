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

final class ModelContextFetchPublisher<Model: PersistentModel>: Publisher {

    // MARK: Typealiases

    typealias Output = [Model]
    typealias Failure = Error


    // MARK: Private properties

    private let contextManager: SwiftDataContextManager
    private let descriptor: FetchDescriptor<Model>

    // MARK: Init

    init(contextManager: SwiftDataContextManager, descriptor: FetchDescriptor<Model>) {
        self.contextManager = contextManager
        self.descriptor = descriptor
    }

    // MARK: Publisher

    func receive<S>(subscriber: S) where S: Subscriber, any Failure == S.Failure, [Model] == S.Input {
        let subscription = ModelContextFetchSubscription(
            subscriber: subscriber,
            contextManager: contextManager,
            descriptor: descriptor
        )
        subscriber.receive(subscription: subscription)
    }
}

// MARK: - ModelContextFetchSubscription

final fileprivate class ModelContextFetchSubscription<Model: PersistentModel, S: Subscriber> where S.Input == [Model], S.Failure == Error {

    // MARK: Private properties

    private let subscriber: S
    private let contextManager: SwiftDataContextManager
    private let descriptor: FetchDescriptor<Model>

    private var subscription: AnyCancellable?

    // MARK: Init

    init(subscriber: S, contextManager: SwiftDataContextManager, descriptor: FetchDescriptor<Model>) {
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
                try await contextManager.fetch(descriptor)
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
