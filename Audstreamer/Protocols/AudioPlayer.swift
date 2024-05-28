//
//  AudioPlayer.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 17..
//

import Combine
import AVFoundation

typealias Second = Double

protocol AudioPlayer {
    func isMuted() -> AnyPublisher<Bool, Error>
    func isPlaying() -> AnyPublisher<Bool, Error>
    func getCurrentSeconds() -> AnyPublisher<Second, Error>
    func getCurrentPlayingAudioInfo() -> AnyPublisher<AudioInfo?, Error>
    func getPlayingFinishedAudioInfo() -> AnyPublisher<AudioInfo, Error>
    func reset() -> AnyPublisher<Void, Error>
    func setMuted(_ isMuted: Bool) -> AnyPublisher<Void, Error>
    func insert(_ item: AudioPlayable, playImmediately: Bool) -> AnyPublisher<Void, Error>
    func play() -> AnyPublisher<Void, Error>
    func pause() -> AnyPublisher<Void, Error>
    func seekForward() -> AnyPublisher<Void, Error>
    func seekBackward() -> AnyPublisher<Void, Error>
    func seek(to second: Second) -> AnyPublisher<Void, Error>
}

enum AudioPlayeError: Error {
    case missingResource
    case cannotLoadAsset(Error?)
    case cannotActivate
}

protocol AudioPlayable {
    var id: String { get }
    var url: URL { get }
    var preferredStartTime: Second? { get }
}

struct AudioInfo: Equatable {
    let id: String
    let duration: Int

    static func == (_ lhs: AudioInfo, _ rhs: AudioInfo) -> Bool {
        lhs.id == rhs.id && lhs.duration == rhs.duration
    }
}
