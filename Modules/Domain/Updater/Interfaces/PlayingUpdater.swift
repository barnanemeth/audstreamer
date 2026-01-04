//
//  PlayingUpdater.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Combine

public protocol PlayingUpdater {
    func startUpdating() -> AnyPublisher<Void, Error>
    func stopUpdating() -> AnyPublisher<Void, Error>
}
