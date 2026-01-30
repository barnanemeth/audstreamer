//
//  Async.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import Combine

extension Publisher {
    public var value: Output {
        get async throws {
            guard let output = try await first().values.first(where: { _ in true }) else {
                throw CancellationError()
            }
            return output
        }
    }
}

extension Publisher where Failure == Never {
    public var bufferedValues: Combine.AsyncPublisher<Publishers.Buffer<Self>> {
        buffer(size: 4, prefetch: .byRequest, whenFull: .dropOldest).values
    }
}

extension Publisher where Failure == Error {
    public var bufferedValues: Combine.AsyncThrowingPublisher<Publishers.Buffer<Self>> {
        buffer(size: 4, prefetch: .byRequest, whenFull: .dropOldest).values
    }
}
