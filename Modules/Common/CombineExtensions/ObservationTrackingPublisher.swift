//
//  ObservationTrackingPublisher.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 30..
//

import Foundation
import Combine
import Observation

public struct ObservationTrackingPublisher<T>: Publisher, Sendable {

    // MARK: Typealiases

    public typealias Output = T
    public typealias Failure = Never

    // MARK: Private properties

    private let apply: @Sendable () -> Output

    // MARK: Init

    public init(_ apply: @autoclosure @Sendable @escaping () -> Output) {
        self.apply = apply
    }

    // MARK: Publisher

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, T == S.Input {
        let subscription = ObservationTrackingSubscription(subscriber: subscriber, apply: apply)
        subscriber.receive(subscription: subscription)
    }
}

// MARK: - ObservationTrackingSubscription

final private class ObservationTrackingSubscription<T, S: Subscriber & Sendable>: Sendable where S.Input == T, S.Failure == Never {

    // MARK: Private properties

    private let subscriber: S
    private let apply: @Sendable () -> T

    // MARK: Init

    init(subscriber: S, apply: @Sendable @escaping () -> T) {
        self.subscriber = subscriber
        self.apply = apply
    }
}

// MARK: - Subscription

extension ObservationTrackingSubscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        observe()
    }

    func cancel() { }
}

// MARK: - Helpers

extension ObservationTrackingSubscription {
    private func observe() {
        let value = withObservationTracking(apply) { [weak self] in
            DispatchQueue.main.async {
                self?.observe()
            }
        }
        _ = subscriber.receive(value)
    }
}
