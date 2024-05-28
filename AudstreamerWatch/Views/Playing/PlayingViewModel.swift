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

    // MARK: Properties

    @Published var episode: EpisodeCommon?

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Actions

extension PlayingViewModel {
    func setEpisode(_ episode: EpisodeCommon) {
        self.episode = episode
    }

    func play() {
        let episode = $episode.setFailureType(to: Error.self).first()
        let currentPlayingAudioInfo = audioPlayer.getCurrentPlayingAudioInfo().first()

        Publishers.Zip(episode, currentPlayingAudioInfo)
            .flatMap { [unowned self] episode, audioInfo -> AnyPublisher<Void, Error> in
                guard let episode, episode.id != audioInfo?.id else { return Just.void() }
                return self.audioPlayer.insert(episode, playImmediately: true)
            }
            .sink()
            .store(in: &cancellables)
    }
}
