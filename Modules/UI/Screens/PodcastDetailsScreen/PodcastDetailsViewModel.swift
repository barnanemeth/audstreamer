//
//  PodcastDetailsViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import Foundation

import Common
import Domain

@Observable
final class PodcastDetailsViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var navigator: Navigator

}

// MARK: - View model

extension PodcastDetailsViewModel: ViewModel {
    func subscribe() async {}
}

// MARK: - Events

extension PodcastDetailsViewModel {
    @MainActor
    func dismiss() {
        navigator.dismiss()
    }

    @MainActor
    func navigateToEpisodes(with podcast: Podcast) {
        navigator.navigate(to: .episodeList(podcast: podcast), method: .push)
    }
}
