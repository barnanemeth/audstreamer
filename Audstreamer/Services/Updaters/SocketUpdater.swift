//
//  SocketUpdater.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 21..
//

import Foundation
import UIKit
import Combine

enum SocketUpdaterError: Error {
    case missingSocketData
}

final class SocketUpdater {

    // MARK: Constants

    private enum Constant {
        static let sendPlaybackStateDelay: DispatchQueue.SchedulerTimeType.Stride = 2
    }

    // MARK: Dependencies

    @Injected private var socket: Socket
    @Injected private var audioPlayer: AudioPlayer
    @Injected private var database: Database

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Public methods

extension SocketUpdater {
    func startUpdating() -> AnyPublisher<Void, Error> {
        Just(start()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func stopUpdating() -> AnyPublisher<Void, Error> {
        Just(stop()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension SocketUpdater {
    private func start() {
        guard cancellables.isEmpty else { return }
        connect()
        setupActiveDeviceSubscription()
        setupCurrentEpisodeSubscription()
        setupPlaybackStateSubsciption()
        setupPlaybackCommandSubscription()
        setupPlaybackSubscription()
        setupActiveDeviceSubscription()
    }

    private func stop() {
        socket.disconnect()
            .sink(receiveCompletion: { [unowned self] _ in self.cancellables.removeAll() },
                  receiveValue: { })
            .store(in: &cancellables)
    }

    private func connect() {
        socket.connect().sink().store(in: &cancellables)
    }

    private func setupActiveDeviceSubscription() {
        DeviceHelper.isThisDeviceCurrent
            .removeDuplicates()
            .flatMap { [unowned self] in self.audioPlayer.setMuted(!$0) }
            .sink()
            .store(in: &cancellables)
    }

    private func setupCurrentEpisodeSubscription() {
        socket.getCurrentEpisode()
            .flatMap { [unowned self] in self.database.getEpisode(id: $0.episodeID).unwrap().first() }
            .flatMap { [unowned self] episode in
                let play = self.audioPlayer.insert(episode, playImmediately: true)
                let databaseUpdate = self.database.updateLastPlayedDate(for: episode)

                return Publishers.Zip(play, databaseUpdate).toVoid()
            }
            .sink()
            .store(in: &cancellables)
    }

    private func setupPlaybackStateSubsciption() {
        socket.getPlaybackState()
            .flatMap { [unowned self] playbackState -> AnyPublisher<(PlaybackStateSocketData, String?), Error> in
                let playbackStatePublisher = Just(playbackState).setFailureType(to: Error.self)
                let episodeID = self.audioPlayer.getCurrentPlayingAudioInfo().first().map { $0?.id }

                return Publishers.Zip(playbackStatePublisher, episodeID).eraseToAnyPublisher()
            }
            .flatMap { [unowned self] playbackState, episodeID -> AnyPublisher<PlaybackStateSocketData, Error> in
                let playbackStatePublisher = Just(playbackState).setFailureType(to: Error.self)

                let insert: AnyPublisher<Void, Error>
                if playbackState.episodeID != episodeID {
                    insert = self.insertEpisode(with: playbackState.episodeID)
                } else {
                    insert = Just.void()
                }

                return Publishers.Zip(playbackStatePublisher, insert).map { $0.0 }.eraseToAnyPublisher()
            }
            .flatMap { [unowned self] playbackState -> AnyPublisher<Void, Error> in
                let updateAudioPlayer: AnyPublisher<Void, Error>
                switch playbackState.state {
                case .playing: updateAudioPlayer = self.audioPlayer.play()
                case .paused: updateAudioPlayer = self.audioPlayer.pause()
                }

                let seek = self.audioPlayer.seek(to: Second(playbackState.currentTime))

                return Publishers.Zip(updateAudioPlayer, seek).toVoid()
            }
            .sink()
            .store(in: &cancellables)
    }

    private func setupPlaybackCommandSubscription() {
        socket.getPlaybackCommand()
            .flatMap { [unowned self] playBackCommand in
                switch playBackCommand {
                case .play: return self.audioPlayer.play()
                case .pause: return self.audioPlayer.pause()
                case .skipBackward: return self.audioPlayer.seekBackward()
                case .skipForward: return self.audioPlayer.seekForward()
                case let .seek(percent): return self.seekCurrent(to: percent)
                }
            }
            .sink()
            .store(in: &cancellables)
    }

    private func seekCurrent(to percent: Double) -> AnyPublisher<Void, Error> {
        audioPlayer.getCurrentPlayingAudioInfo()
            .first()
            .flatMap { [unowned self] audioInfo -> AnyPublisher<Void, Error> in
                guard let audioInfo = audioInfo else { return Empty(completeImmediately: true).eraseToAnyPublisher() }
                let seekSeconds = Double(audioInfo.duration) * percent
                return self.audioPlayer.seek(to: seekSeconds)
            }
            .replaceEmpty(with: ())
            .eraseToAnyPublisher()
    }

    private func setupPlaybackSubscription() {
        let currentPlayingAudioIdentifier = audioPlayer.getCurrentPlayingAudioInfo().compactMap { $0?.id }
        let currentSeconds = audioPlayer.getCurrentSeconds()

        Publishers.CombineLatest(currentPlayingAudioIdentifier, currentSeconds)
            // swiftlint:disable:next large_tuple
            .flatMap { [unowned self] audioID, currentSeconds -> AnyPublisher<(String, Second, Int, Bool), Error> in
                let audioIDPublisher = Just(audioID).setFailureType(to: Error.self)
                let currentSecondsPublisher = Just(currentSeconds).setFailureType(to: Error.self)
                let devicesCount = self.socket.getDeviceList().first().map { $0.count }
                let isPlaying = self.audioPlayer.isPlaying().first()

                return Publishers.Zip4(audioIDPublisher, currentSecondsPublisher, devicesCount, isPlaying)
                    .eraseToAnyPublisher()
            }
            .flatMap { [unowned self] in
                self.sendPlaybackState(audioID: $0, currentSeconds: $1, devicesCount: $2, isPlaying: $3)
            }
            .sink()
            .store(in: &cancellables)
    }

    private func sendPlaybackState(audioID: String,
                                   currentSeconds: Second,
                                   devicesCount: Int,
                                   isPlaying: Bool) -> AnyPublisher<Void, Error> {
        guard devicesCount > 1 else { return Just.void() }
        return DeviceHelper.isThisDeviceCurrent
            .first()
            .flatMap { [unowned self] isCurrent -> AnyPublisher<Void, Error> in
                guard isCurrent && currentSeconds.isNormal else { return Just.void() }
                let playbackState = PlaybackStateSocketData(
                    episodeID: audioID,
                    state: isPlaying ? .playing : .paused,
                    currentTime: Int(currentSeconds)
                )
                return self.socket.sendPlaybackState(playbackState)
            }
            .eraseToAnyPublisher()
    }

    private func insertEpisode(with id: String) -> AnyPublisher<Void, Error> {
        database.getEpisode(id: id)
            .first()
            .flatMap { [unowned self] episode -> AnyPublisher<Void, Error> in
                guard let episode = episode else { return Just.void() }
                return self.audioPlayer.insert(episode, playImmediately: false)
            }
            .eraseToAnyPublisher()
    }
}
