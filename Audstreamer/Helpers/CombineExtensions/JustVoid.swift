//
//  JustVoid.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 03..
//

import Combine

extension Just where Output == Void {
    static func void<F>() -> AnyPublisher<Void, F> where F: Error {
        Just(()).setFailureType(to: F.self).eraseToAnyPublisher()
    }
}
