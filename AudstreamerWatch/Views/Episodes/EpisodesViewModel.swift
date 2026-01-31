//
//  EpisodesViewModel.swift
//  AudstreamerWatch Watch App
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import Foundation
import Combine
import AVFoundation

import Common
import Domain

final class EpisodesViewModel: ObservableObject {

    // MARK: Dependencies

    @Injected private var episodeService: EpisodeService
    @Injected private var audioPlayer: AudioPlayer

    // MARK: Properties

    @Published private(set) var title = About.appName
    @Published private(set) var episodes = [EpisodeRow.Data]()

    // MARK: Init

    init() {
        setupBindings()
    }
}

// MARK: - Helpers

extension EpisodesViewModel {
    private func setupBindings() {
        let episodes = episodeService.episodes(matching: nil).removeDuplicates()
        let nowPlayingID = audioPlayer.getCurrentPlayingAudioInfo().removeDuplicates().map(\.?.id).prepend(nil)

        Publishers.CombineLatest(episodes, nowPlayingID)
            .map { [unowned self] in mapEpisodes($0, currentlyPlayingID: $1) }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$episodes)
    }

    private func mapEpisodes(_ episodes: [Episode], currentlyPlayingID: String?) -> [EpisodeRow.Data] {
        episodes.map { episode in
            EpisodeRow.Data(
                episode: episode,
                isPlaying: episode.id == currentlyPlayingID,
                transferringState: {
                    if episode.isOnWatch {
                        .finished
                    } else {
                        .inProgress
                    }
                }()
            )
        }
    }
}
