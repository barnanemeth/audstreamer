//
//  PodcastListViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import Foundation
import Combine
import SwiftUI

import Common
import Domain

@Observable
final class PodcastListViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var podcastService: PodcastService
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    private(set) var podcasts = [Podcast]()
    private(set) var isAddingPodcastLoading = false
}

// MARK: - View model

extension PodcastListViewModel: ViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeToPodcasts() }
        }
    }
}

// MARK: - Events

extension PodcastListViewModel {
    @MainActor
    func showPodcastDetails(for podcast: Podcast, namesapce: Namespace.ID) {
        navigator.navigate(to: .podcastDetails(podcast: podcast, namespace: namesapce), method: .push)
    }

    @MainActor
    func showNewPodcast() {
        navigator.navigate(to: .addPodcast, method: .managedSheet)
    }
}

// MARK: - Helpers

extension PodcastListViewModel {
    @MainActor
    private func subscribeToPodcasts() async {
        let publisher = podcastService.savedPodcasts(sortingPreference: .byLatestRelease).replaceError(with: [])
        for try await podcasts in publisher.bufferedValues {
            self.podcasts = podcasts
        }
    }
}
