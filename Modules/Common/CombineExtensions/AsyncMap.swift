//
//  AsyncMap.swift
//  Common
//
//  Created by Barna Nemeth on 2026. 01. 06..
//

import Combine

extension Publisher {
    public func asyncMap<T>(_ transform: @escaping (Output) async -> T) -> AnyPublisher<T, Never> where Failure == Never {
        flatMapLatest { value in
            AsyncPublisher<T> {
                await transform(value)
            }
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher {
    public func asyncTryMap<T>(_ transform: @escaping (Output) async throws -> T) -> AnyPublisher<T, Failure> where Failure: Error {
        flatMapLatest { value in
            ThrowingAsyncPublisher<T, Failure> {
                try await transform(value)
            }
        }
        .eraseToAnyPublisher()
    }
}
