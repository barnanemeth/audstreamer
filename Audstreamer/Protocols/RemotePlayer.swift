//
//  NowPlayingInfo.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 19..
//

import Foundation
import Combine

protocol RemotePlayer {
    func getEvents() -> AnyPublisher<RemotePlayerEvent, Error>
    func updateNowPlaying(_ item: NowPlayable, preferredDuration: Int) -> AnyPublisher<Void, Error>
    func updateElapsedTime(_ elapsedTime: Double?) -> AnyPublisher<Void, Error>
    func updatePlaybackState(isPlaying: Bool) -> AnyPublisher<Void, Error>
}

protocol NowPlayable {
    var title: String { get }
    var duration: Int { get }
    var imageURL: URL? { get }
}

enum RemotePlayerEvent {
    case play
    case pause
    case skipForward
    case skipBackward
    case changePlaybackPosition(TimeInterval)
    case nextTrack
    case previousTrack
    case seekForward
    case seekBackward
    case likeCommand
    case dislikeCommand
}
