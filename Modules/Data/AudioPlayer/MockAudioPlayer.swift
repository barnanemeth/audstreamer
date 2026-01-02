//
//  MockAudioPlayer.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 17..
//

import Foundation
import Combine

import Domain

struct MockAudioPlayer {
    private let isPlayingSubject = CurrentValueSubject<Bool, Error>(false)
}

// MARK: - AudioPlayer

extension MockAudioPlayer: AudioPlayer {
    func isMuted() -> AnyPublisher<Bool, any Error> {
        Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func isPlaying() -> AnyPublisher<Bool, any Error> {
        isPlayingSubject.eraseToAnyPublisher()
    }

    func getCurrentSeconds() -> AnyPublisher<Second, any Error> {
        Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .scan(0) { result, _ in
                if result == 60 {
                    0
                } else {
                    result + 1
                }
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getCurrentPlayingAudioInfo() -> AnyPublisher<AudioInfo?, any Error> {
        let audioInfo = AudioInfo(id: "id0", duration: 60)
        return Just(audioInfo).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func getPlayingFinishedAudioInfo() -> AnyPublisher<AudioInfo, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func reset() -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func setMuted(_ isMuted: Bool) -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func insert(_ item: any AudioPlayable, playImmediately: Bool) -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func play() -> AnyPublisher<Void, any Error> {
        Just(isPlayingSubject.send(true)).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func pause() -> AnyPublisher<Void, any Error> {
        Just(isPlayingSubject.send(false)).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func seekForward() -> AnyPublisher<Void, any Error> {
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func seekBackward() -> AnyPublisher<Void, any Error> {
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func seek(to second: Second) -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
}
