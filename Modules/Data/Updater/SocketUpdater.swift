//
//  SocketUpdater.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Combine

protocol SocketUpdater {
    func startUpdating() -> AnyPublisher<Void, Error>
    func stopUpdating() -> AnyPublisher<Void, Error>
}
