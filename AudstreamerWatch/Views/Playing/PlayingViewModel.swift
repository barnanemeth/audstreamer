//
//  PlayingViewModel.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 03..
//

import Foundation
import Combine
import AVFoundation

final class PlayingViewModel: ObservableObject {

    // MARK: Dependencies

    @Injected private var audioPlayer: AudioPlayer
    @Injected private var episodeService: EpisodeService

    // MARK: Properties

    @Published private(set) var currentlyPlayingEpisode: EpisodeCommon?
    @Published private(set) var isPlaying = false

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        subscribeToCurrenEpisode()
        subscribeToPlayingState()
    }
}

// MARK: - Actions

extension PlayingViewModel {
    func setEpisode(_ episode: EpisodeCommon) {
        audioPlayer.getCurrentPlayingAudioInfo()
            .first()
            .flatMap { [unowned self] audioInfo -> AnyPublisher<Void, Error> in
                guard episode.id != audioInfo?.id else { return Just.void() }
                return self.audioPlayer.insert(episode, playImmediately: true)
            }
            .sink()
            .store(in: &cancellables)
    }

    func playPause() {
        let publisher: AnyPublisher<Void, Error> = if isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }

        publisher
            .sink()
            .store(in: &cancellables)
    }

    func seekBackward() {
        audioPlayer.seekBackward()
            .sink()
            .store(in: &cancellables)
    }

    func seekForward() {
        audioPlayer.seekForward()
            .sink()
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension PlayingViewModel {
    private func subscribeToCurrenEpisode() {
        let currentAudioID = audioPlayer.getCurrentPlayingAudioInfo().compactMap(\.?.id).removeDuplicates()
        let episodes = episodeService.getEpisodes()

        Publishers.CombineLatest(currentAudioID, episodes)
            .map { currentAudioID, episodes in
                episodes.first(where: { $0.id == currentAudioID })
            }
            .receive(on: DispatchQueue.main)
            .replaceError(with: nil)
            .assign(to: &$currentlyPlayingEpisode)
    }

    private func subscribeToPlayingState() {
        audioPlayer.isPlaying()
            .removeDuplicates()
            .replaceError(with: false)
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)
    }
}
