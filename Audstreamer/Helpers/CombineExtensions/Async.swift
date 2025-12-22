//
//  Async.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import Combine

extension Publisher {
    var value: Output {
        get async throws {
            guard let output = try await first().values.first(where: { _ in true }) else {
                throw CancellationError()
            }
            return output
        }
    }
}
