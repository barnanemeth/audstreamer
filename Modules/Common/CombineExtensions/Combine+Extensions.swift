//
//  Combine+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 15..
//

import Combine

extension Publisher {
    public func sink() -> AnyCancellable {
        sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }

    public func sink(receiveValue: @escaping ((Output) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }

    public func toVoid() -> AnyPublisher<Void, Failure> {
        map { _ in () }.eraseToAnyPublisher()
    }
}
