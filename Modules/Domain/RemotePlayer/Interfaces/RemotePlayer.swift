//
//  NowPlayingInfo.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 19..
//

import Foundation
import Combine

public protocol RemotePlayer {
    func getEvents() -> AnyPublisher<RemotePlayerEvent, Error>
    func updateNowPlaying(_ item: NowPlayable, preferredDuration: Int) -> AnyPublisher<Void, Error>
    func updateElapsedTime(_ elapsedTime: Double?) -> AnyPublisher<Void, Error>
    func updatePlaybackState(isPlaying: Bool) -> AnyPublisher<Void, Error>
}
