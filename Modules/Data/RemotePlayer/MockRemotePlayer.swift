//
//  MockRemotePlayer.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 17..
//

import Foundation
import Combine

import Domain

struct MockRemotePlayer { }

// MARK: - RemotePlayer

extension MockRemotePlayer: RemotePlayer {
    func getEvents() -> AnyPublisher<RemotePlayerEvent, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func updateNowPlaying(_ item: any NowPlayable, preferredDuration: Int) -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func updateElapsedTime(_ elapsedTime: Double?) -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func updatePlaybackState(isPlaying: Bool) -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
}
