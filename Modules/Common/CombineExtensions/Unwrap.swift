//
//  Unwrap.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 23..
//

import Combine

extension Publisher {
    public func unwrap<T>() -> Publishers.CompactMap<Self, T> where Output == T? {
        compactMap { $0 }
    }
}
