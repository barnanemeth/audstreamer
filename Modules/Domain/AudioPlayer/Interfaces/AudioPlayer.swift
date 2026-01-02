//
//  AudioPlayer.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 17..
//

import Combine
import AVFoundation

public protocol AudioPlayer {
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
