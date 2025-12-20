//
//  EpisodesViewModel.swift
//  AudstreamerWatch Watch App
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import Foundation
import Combine
import AVFoundation

final class EpisodesViewModel: ObservableObject {

    // MARK: Dependencies

    @Injected private var episodeService: EpisodeService

    // MARK: Properties

    @Published private(set) var title = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    @Published private(set) var episodes = [EpisodeCommon]()

    // MARK: Init

    init() {
        setupBindings()
    }
}

// MARK: - Helpers

extension EpisodesViewModel {
    private func setupBindings() {
        episodeService.getEpisodes()
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$episodes)
    }
}
