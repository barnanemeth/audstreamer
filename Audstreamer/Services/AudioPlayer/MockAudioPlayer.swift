//
//  MockAudioPlayer.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 17..
//

import Foundation
import Combine

struct MockAudioPlayer { }

// MARK: - AudioPlayer

extension MockAudioPlayer: AudioPlayer {
    func isMuted() -> AnyPublisher<Bool, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
    
    func isPlaying() -> AnyPublisher<Bool, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
    
    func getCurrentSeconds() -> AnyPublisher<Second, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
    
    func getCurrentPlayingAudioInfo() -> AnyPublisher<AudioInfo?, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
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
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
    
    func pause() -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
    
    func seekForward() -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
    
    func seekBackward() -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
    
    func seek(to second: Second) -> AnyPublisher<Void, any Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
}
