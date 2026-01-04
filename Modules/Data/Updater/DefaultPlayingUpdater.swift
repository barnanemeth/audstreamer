//
//  DefaultPlayingUpdater.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 19..
//

import Foundation
import Combine

import Common
import Domain

final class DefaultPlayingUpdater {

    // MARK: Dependencies

    @Injected private var audioPlayer: AudioPlayer
    @Injected private var database: Database
    @Injected private var remotePlayer: RemotePlayer
    @Injected private var socket: Socket
    @Injected private var downloadService: DownloadService

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - PlayingUpdater

extension DefaultPlayingUpdater: PlayingUpdater {
    func startUpdating() -> AnyPublisher<Void, Error> {
        Just(start()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func stopUpdating() -> AnyPublisher<Void, Error> {
        Just(stop()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultPlayingUpdater {
    private func start() {
        guard cancellables.isEmpty else { return }
        setupCurrentPlayingAudioSubscription()
        setupElapsedTimeSubscription()
        setupRemotePlayerEventSubscription()
        setupDownloadSubscription()
    }

    private func stop() {
        cancellables.removeAll()
    }

    private func setupCurrentPlayingAudioSubscription() {
        audioPlayer.getCurrentPlayingAudioInfo()
            .unwrap()
            .removeDuplicates()
            .flatMap { [unowned self] audioInfo -> AnyPublisher<(Episode, Int), Error> in
                let episode = self.database.getEpisode(id: audioInfo.id).first().unwrap()
                let durationPublisher = Just(audioInfo.duration).setFailureType(to: Error.self)

                return Publishers.Zip(episode, durationPublisher).eraseToAnyPublisher()
            }
            .flatMap { [unowned self] in self.remotePlayer.updateNowPlaying($0, preferredDuration: $1) }
            .sink()
            .store(in: &cancellables)
    }

    private func setupElapsedTimeSubscription() {
        audioPlayer.getCurrentSeconds()
            .flatMap { [unowned self] in self.remotePlayer.updateElapsedTime($0) }
            .sink()
            .store(in: &cancellables)
    }

    private func setupRemotePlayerEventSubscription() {
        remotePlayer.getEvents()
            .flatMap { [unowned self] remoteEvent in
                switch remoteEvent {
                case .play: return self.audioPlayer.play()
                case .pause: return self.audioPlayer.pause()
                case .skipForward, .seekForward, .nextTrack: return  self.audioPlayer.seekForward()
                case .skipBackward, .seekBackward, .previousTrack: return self.audioPlayer.seekBackward()
                case let .changePlaybackPosition(position): return self.audioPlayer.seek(to: position)
                default: return Just.void()
                }
            }
            .sink()
            .store(in: &cancellables)
    }

    private func setupDownloadSubscription() {
        downloadService.getEvent()
            .filter { event in
                switch event {
                case .finished, .deleted: return true
                default: return false
                }
            }
            .flatMap { [unowned self] event -> AnyPublisher<(DownloadEvent, String?), Error> in
                let downloadEventPublisher = Just(event).setFailureType(to: Error.self)
                let currentAudioID = self.audioPlayer.getCurrentPlayingAudioInfo().first().map { $0?.id }

                return Publishers.Zip(downloadEventPublisher, currentAudioID).eraseToAnyPublisher()
            }
            .flatMap { [unowned self] in self.reloadCurrentAudioIfNeeded(event: $0, currentAudioID: $1) }
            .sink()
            .store(in: &cancellables)
    }

    private func reloadCurrentAudioIfNeeded(event: DownloadEvent,
                                            currentAudioID: String?) -> AnyPublisher<Void, Error> {
        guard let currentAudioID = currentAudioID else { return Just.void() }

        switch event {
        case .finished(let item), .deleted(let item):
            guard item.id == currentAudioID else { return Just.void() }
            return database.getEpisode(id: currentAudioID)
                .first()
                .flatMap { [unowned self] episode -> AnyPublisher<Episode, Error> in
                    guard let episode = episode else { return Empty(completeImmediately: true).eraseToAnyPublisher() }

                    let episodePublisher = Just(episode).setFailureType(to: Error.self)
                    let pause = self.audioPlayer.pause()

                    return Publishers.Zip(episodePublisher, pause).map { $0.0 }.eraseToAnyPublisher()
                }
                .flatMap { [unowned self] in self.audioPlayer.insert($0, playImmediately: false) }
                .eraseToAnyPublisher()
        default:
            return Just.void()
        }
    }
}
