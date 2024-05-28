//
//  Promise.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 12. 24..
//

import Foundation
import Combine

struct Promise<Output, Failure>: Publisher where Failure: Error {

    // MARK: Typealiases

    typealias Fulfill = (@escaping (Result<Output, Failure>) -> Void) -> Void

    // MARK: Private properties

    private let fulfill: Fulfill

    // MARK: Init

    init(_ fulfill: @escaping Fulfill) {
        self.fulfill = fulfill
    }

    // MARK: Publisher

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = PromiseSubscription(subscriber: subscriber, fulfill: fulfill)
        subscriber.receive(subscription: subscription)
    }
}

private struct PromiseSubscription<S: Subscriber, Output, Failure> where Output == S.Input, Failure == S.Failure {

    // MARK: Private properties

    private let subscriber: S
    private let fulfill: Promise<Output, Failure>.Fulfill

    // MARK: Init

    init(subscriber: S, fulfill: @escaping Promise<Output, Failure>.Fulfill) {
        self.subscriber = subscriber
        self.fulfill = fulfill
    }
}

// MARK: - Subscription

extension PromiseSubscription: Subscription {
    var combineIdentifier: CombineIdentifier { CombineIdentifier() }

    func request(_ demand: Subscribers.Demand) {
        fulfill { result in
            switch result {
            case let .success(value):
                _ = subscriber.receive(value)
                subscriber.receive(completion: .finished)
            case let .failure(error):
                subscriber.receive(completion: .failure(error))
            }
        }
    }

    func cancel() { }
}
