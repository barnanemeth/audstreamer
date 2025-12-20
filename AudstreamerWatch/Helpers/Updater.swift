//
//  Updater.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 05..
//

import Foundation
import Combine

final class Updater {

    // MARK: Dependencies

    @Injected private var episodeService: EpisodeService
    @Injected private var remotePlayer: RemotePlayer
    @Injected private var audioPlayer: AudioPlayer

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private lazy var currentPlayingAudioInfo: AnyPublisher<AudioInfo?, Error> = {
        audioPlayer.getCurrentPlayingAudioInfo().shareReplay()
    }()
}

// MARK: - Public methods

extension Updater {
    func startUpdating() {
        guard cancellables.isEmpty else { return }
        subscribeToCurrentPlayingAudioInfo()
        subscribeToCurrentSeconds()
        subscribeToRemotePlayerEvents()
    }

    func stopUpdating() {
        guard !cancellables.isEmpty else { return }
        cancellables.removeAll()
    }
}

// MARK: - Helpers

extension Updater {
    private func subscribeToCurrentPlayingAudioInfo() {
        currentPlayingAudioInfo
            .unwrap()
            .removeDuplicates()
            .flatMap { [unowned self] audioInfo in
                let episode = self.episodeService.getEpisodes()
                    .map { $0.first(where: { $0.id == audioInfo.id }) }
                    .unwrap()
                    .first()
                let durationPublisher = Just(audioInfo.duration).setFailureType(to: Error.self)

                return Publishers.Zip(episode, durationPublisher).eraseToAnyPublisher()
            }
            .flatMap { [unowned self] audioInfo, duration -> AnyPublisher<Void, Error> in
                let updateNowPlaying = self.remotePlayer.updateNowPlaying(audioInfo, preferredDuration: duration)
                let updateLastPlayedDate = self.episodeService.updateLastPlayedDate(Date(), for: audioInfo.id)

                return Publishers.Zip(updateNowPlaying, updateLastPlayedDate).toVoid()
            }
            .sink()
            .store(in: &cancellables)
    }

    private func subscribeToCurrentSeconds() {
        Publishers.CombineLatest(audioPlayer.getCurrentSeconds(), currentPlayingAudioInfo)
            .throttle(for: 30, scheduler: DispatchQueue.global(qos: .background), latest: true)
            .flatMap { [unowned self] seconds, audioInfo -> AnyPublisher<Void, Error> in
                guard let audioInfo, !seconds.isNaN else { return Just.void() }

                let updateNowPlaying = self.remotePlayer.updateElapsedTime(seconds)
                let updateLastPosition = self.episodeService.updateLastPosition(Int(seconds), for: audioInfo.id)

                return Publishers.Zip(updateNowPlaying, updateLastPosition).toVoid()
            }
            .sink()
            .store(in: &cancellables)

        audioPlayer.getCurrentSeconds()
            .flatMap { [unowned self] in self.remotePlayer.updateElapsedTime($0) }
            .sink()
            .store(in: &cancellables)
    }

    private func subscribeToRemotePlayerEvents() {
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
}
