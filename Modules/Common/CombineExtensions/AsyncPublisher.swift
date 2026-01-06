//
//  AsyncPublisher.swift
//  Common
//
//  Created by Barna Nemeth on 2026. 01. 06..
//

import Combine

public struct AsyncPublisher<Output>: Publisher {

    // MARK: Typealiases

    public typealias Output = Output
    public typealias Failure = Never

    // MARK: Properties

    private let task: () async -> Output

    // MARK: Init

    public init(_ task: @escaping () async -> Output) {
        self.task = task
    }

    // MARK: Publisher

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = AsyncSubscription(subscriber: subscriber, task: task)
        subscriber.receive(subscription: subscription)
    }
}

public struct ThrowingAsyncPublisher<Output, Failure: Error>: Publisher {

    // MARK: Typealiases

    public typealias Output = Output
    public typealias Failure = Failure

    // MARK: Properties

    private let task: () async throws -> Output

    // MARK: Init

    public init(_ task: @escaping () async throws -> Output) {
        self.task = task
    }

    // MARK: Publisher

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input, Output: Sendable {
        let subscription = AsyncSubscription(subscriber: subscriber, task: task)
        subscriber.receive(subscription: subscription)
    }
}

// MARK: - AsyncSubscription

fileprivate final class AsyncSubscription<Output, Failure, S: Subscriber> where S.Input == Output, S.Failure == Failure, Output: Sendable {

    // MARK: Private properties

    private let subscriber: S
    private let task: () async throws -> Output

    private var executorTask: Task<Void, Never>?

    // MARK: Init

    init(subscriber: S, task: @escaping () async throws -> Output, executorTask: Task<Void, Never>? = nil) {
        self.subscriber = subscriber
        self.task = task
        self.executorTask = executorTask
    }
}

// MARK: - AsyncSubscription + Subscription

extension AsyncSubscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        executorTask = Task {
            do {
                try Task.checkCancellation()
                let value = try await task()
                try Task.checkCancellation()
                _ = subscriber.receive(value)
                subscriber.receive(completion: .finished)
            } catch {
                guard let failure = error as? Failure else {
                    return subscriber.receive(completion: .finished)
                }
                subscriber.receive(completion: .failure(failure))
            }
        }
    }
    
    func cancel() {
        executorTask?.cancel()
    }
}
