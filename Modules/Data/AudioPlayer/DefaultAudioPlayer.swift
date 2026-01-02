//
//  DefaultAudioPlayer.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 17..
//

import Foundation
import Combine
import AVFoundation

import Common
import Domain

final class DefaultAudioPlayer {

    // MARK: Constants

    private enum Constant {
        static let timeObserverInterval = CMTime(seconds: 1, preferredTimescale: 1)
        static let timeObserverQueue = DispatchQueue.main
        static let loadQueue = DispatchQueue.global(qos: .userInitiated)
        static let receiveQueue = DispatchQueue.main
        static let durationResourceKey = "duration"
        static let preferredTimescale: CMTimeScale = 1
        static let seekInterval: TimeInterval = 10
        static let defaultPlayingRate: Float = 1
    }

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private let audioSession = AVAudioSession.sharedInstance()
    private let audioPlayer = AVQueuePlayer()
    private var currentlyPlayingEpisodeID: String?
    private var timeObserverReference: Any?
    private let currentSecondsSubject = CurrentValueSubject<Second?, Error>(nil)
    private let currentPlayingAudioInfoSubject = CurrentValueSubject<AudioInfo?, Error>(nil)
    private let playingFinishedAudioInfoSubject = PassthroughSubject<AudioInfo, Error>()

    private lazy var periodicTimeObserver: ((CMTime) -> Void) = { [unowned self] time in
        self.currentSecondsSubject.send(time.seconds)
    }

    // MARK: Init

    init() {
        initAudioSession()
        setupObservers()
    }

    deinit {
        removeObservers()
    }
}

// MARK: - AudioPlayer

extension DefaultAudioPlayer: AudioPlayer {
    func isMuted() -> AnyPublisher<Bool, Error> {
        audioPlayer.publisher(for: \.isMuted)
            .setFailureType(to: Error.self)
            .receive(on: Constant.receiveQueue)
            .eraseToAnyPublisher()
    }

    func isPlaying() -> AnyPublisher<Bool, Error> {
        audioPlayer.publisher(for: \.rate)
            .setFailureType(to: Error.self)
            .map { $0 != .zero }
            .receive(on: Constant.receiveQueue)
            .eraseToAnyPublisher()
    }

    func getCurrentSeconds() -> AnyPublisher<Second, Error> {
        currentSecondsSubject
            .unwrap()
            .receive(on: Constant.receiveQueue)
            .eraseToAnyPublisher()
    }

    func getCurrentPlayingAudioInfo() -> AnyPublisher<AudioInfo?, Error> {
        currentPlayingAudioInfoSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getPlayingFinishedAudioInfo() -> AnyPublisher<AudioInfo, Error> {
        playingFinishedAudioInfoSubject.eraseToAnyPublisher()
    }

    func reset() -> AnyPublisher<Void, Error> {
        Just(resetPlayer()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func setMuted(_ isMuted: Bool) -> AnyPublisher<Void, Error> {
        guard audioPlayer.isMuted != isMuted else { return Just.void() }
        return Just(audioPlayer.isMuted = isMuted).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func insert(_ item: AudioPlayable, playImmediately: Bool) -> AnyPublisher<Void, Error> {
        Promise<Void, Error> { [unowned self] promise in
            self.resetPlayer()
            self.insert(item: item, playImmediately: playImmediately, completion: { promise($0) })
        }
        .flatMap { [unowned self] in self.activateSessionIfNeeded() }
        .handleEvents(receiveOutput: { [unowned self] in
            guard playImmediately else { return }
            self.audioPlayer.play()
        })
        .eraseToAnyPublisher()
    }

    func play() -> AnyPublisher<Void, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .tryMap { [unowned self] in
                try self.audioSession.setActive(true)
                self.audioPlayer.rate = Constant.defaultPlayingRate
            }
            .handleEvents(receiveOutput: { [unowned self] _ in self.publishCurrentSeconds() })
            .eraseToAnyPublisher()
    }

    func pause() -> AnyPublisher<Void, Error> {
        Just(audioPlayer.pause())
            .setFailureType(to: Error.self)
            .handleEvents(receiveOutput: { [unowned self] _ in self.publishCurrentSeconds() })
            .eraseToAnyPublisher()
    }

    func seekForward() -> AnyPublisher<Void, Error> {
        seek(by: Constant.seekInterval)
    }

    func seekBackward() -> AnyPublisher<Void, Error> {
        seek(by: -Constant.seekInterval)
    }

    func seek(to second: Second) -> AnyPublisher<Void, Error> {
        let targetTime = CMTime(seconds: second, preferredTimescale: Constant.preferredTimescale)
        return Promise<Void, Error> { [unowned self] promise in
            self.audioPlayer.seek(to: targetTime) { _ in promise(.success(())) }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultAudioPlayer {
    private func initAudioSession() {
        do {
            #if os(watchOS)
            try audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio)
            #else
            try audioSession.setCategory(.playback)
            #endif
        } catch {
            preconditionFailure("Cannot initialize AVAudioSession: \(error)")
        }
    }

    private func setupObservers() {
        timeObserverReference = audioPlayer.addPeriodicTimeObserver(
            forInterval: Constant.timeObserverInterval,
            queue: Constant.timeObserverQueue,
            using: periodicTimeObserver
        )

        NotificationCenter.default.publisher(for: NSNotification.Name.AVPlayerItemDidPlayToEndTime)
            .toVoid()
            .flatMap { [unowned self] in self.handleAudioPlayerFinishedPlaying().replaceError(with: ()) }
            .sink()
            .store(in: &cancellables)
    }

    private func removeObservers() {
        if let timeObserverReference = timeObserverReference {
            audioPlayer.removeTimeObserver(timeObserverReference)
        }
    }

    private func insert(item: AudioPlayable,
                        playImmediately: Bool,
                        completion: @escaping ((Result<Void, Error>) -> Void)) {
        let asset = AVURLAsset(url: item.url)
        let audioIdentifier = item.id
        let audioPreferredStartTime = item.preferredStartTime
        #if !os(watchOS)
        asset.resourceLoader.setDelegate(nil, queue: Constant.loadQueue)
        #endif
        asset.loadValuesAsynchronously(forKeys: [Constant.durationResourceKey]) { [unowned self] in
            do {
                try self.checkAssetLoadState(for: asset)
                let playerItem = AVPlayerItem(asset: asset)
                self.audioPlayer.insert(playerItem, after: nil)
                let seconds = audioPreferredStartTime ?? .zero
                let seekTime = CMTime(seconds: seconds, preferredTimescale: Constant.preferredTimescale)
                self.audioPlayer.seek(to: seekTime)
                let audioInfo = AudioInfo(id: audioIdentifier, duration: Int(asset.duration.seconds.rounded(.up)))
                self.currentPlayingAudioInfoSubject.send(audioInfo)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func activateSessionIfNeeded() -> AnyPublisher<Void, Error> {
        Promise<Void, Error> { [unowned self] promise in
            #if os(watchOS)
            self.audioSession.activate(options: [], completionHandler: { success, error in
                if let error {
                    return promise(.failure(error))
                }
                if !success {
                    return promise(.failure(AudioPlayeError.cannotActivate))
                }
                promise(.success(()))
            })
            #else
            do {
                try self.audioSession.setActive(true)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }

            #endif
        }
        .eraseToAnyPublisher()
    }

    private func getTargetTime(with interval: TimeInterval) -> CMTime {
        let currentTime = audioPlayer.currentTime()
        return CMTimeMakeWithSeconds(currentTime.seconds + interval, preferredTimescale: currentTime.timescale)
    }

    private func seek(by interval: TimeInterval) -> AnyPublisher<Void, Error> {
        Promise<Void, Error> { [unowned self] promise in
            self.audioPlayer.seek(to: self.getTargetTime(with: interval)) { _ in promise(.success(())) }
        }
        .eraseToAnyPublisher()
    }

    private func checkAssetLoadState(for asset: AVURLAsset) throws {
        var error: NSError?
        switch asset.statusOfValue(forKey: Constant.durationResourceKey, error: &error) {
        case .loaded: return
        case .failed, .cancelled: throw AudioPlayeError.cannotLoadAsset(error)
        default: preconditionFailure("Unhandled case")
        }
    }

    private func resetPlayer() {
        audioPlayer.removeAllItems()
        currentPlayingAudioInfoSubject.send(nil)
    }

    private func handleAudioPlayerFinishedPlaying() -> AnyPublisher<Void, Error> {
        currentPlayingAudioInfoSubject
            .first()
            .map { [unowned self] audioInfo in
                guard let audioInfo = audioInfo else { return }

                self.playingFinishedAudioInfoSubject.send(audioInfo)

                let seconds = CMTime(seconds: .zero, preferredTimescale: Constant.preferredTimescale)
                self.audioPlayer.pause()
                self.audioPlayer.seek(to: seconds)
                self.currentSecondsSubject.send(.zero)
            }
            .eraseToAnyPublisher()
    }

    private func publishCurrentSeconds() {
        currentSecondsSubject.send(audioPlayer.currentTime().seconds)
    }
}
