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

extension Publisher {
    public func asAsyncStream() -> AsyncStream<Output> where Failure == Never {
        AsyncStream<Output> { continuation in
            let cancellable = sink(receiveCompletion: { completion in
                guard case .finished = completion else { return }
                continuation.finish()
            }, receiveValue: { continuation.yield($0) })
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    public func asAsyncStream() -> AsyncThrowingStream<Output, Failure> where Failure == Error {
        AsyncThrowingStream<Output, Failure> { continuation in
            let cancellable = sink(receiveCompletion: { completion in
                switch completion {
                case .finished: continuation.finish()
                case let .failure(error): continuation.finish(throwing: error)
                }
            }, receiveValue: { continuation.yield($0) })
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
