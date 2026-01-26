//
//  SavedPodcastsWidgetViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 26..
//

import Foundation
import Combine

import Common
import Domain

@Observable
final class SavedPodcastsWidgetViewModel {

    // MARK: Constants

    private enum Constant {
        static let maximumSavedPodcastsToShow = 6
    }

    // MARK: Dependencies

    @ObservationIgnored @Injected private var podcastService: PodcastService

    // MARK: Properties

    private(set) var podcasts: [Podcast]?
}

// MARK: - View model

extension SavedPodcastsWidgetViewModel: ViewModel {
    func subscribe() async {
        await subscribeToPodcasts()
    }
}

// MARK: - Helpers

extension SavedPodcastsWidgetViewModel {
    @MainActor
    private func subscribeToPodcasts() async {
        let publisher = podcastService.savedPodcasts().replaceError(with: [])
        for await podcasts in publisher.asAsyncStream() {
            self.podcasts = Array(podcasts.prefix(Constant.maximumSavedPodcastsToShow))

        }
    }
}
