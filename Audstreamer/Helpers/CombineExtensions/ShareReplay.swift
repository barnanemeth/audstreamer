//
//  ShareReplay.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 19..
//

import Combine

extension Publisher {
    func shareReplay() -> AnyPublisher<Output, Failure> {
        map { Optional($0) }
        .multicast { CurrentValueSubject(Optional.none) }
        .autoconnect()
        .unwrap()
        .eraseToAnyPublisher()
    }
}
