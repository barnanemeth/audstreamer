//
//  TrendingWidgetViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 26..
//

import Foundation
import Combine

import Common
import Domain

@Observable
final class TrendingWidgetViewModel {

    // MARK: Constants

    private enum Constant {
        static let maximumPodcastsToShow = 10
        static let maximumPodcastsFetchOverhead = 10
    }

    // MARK: Dependencies

    @ObservationIgnored @Injected private var podcastService: PodcastService

    // MARK: Properties

    private(set) var podcasts: [Podcast]?
    private(set) var isErrorOccurred = false
}

// MARK: - View model

extension TrendingWidgetViewModel: ViewModel {
    func subscribe() async {
        await refreshPodcasts()
    }
}

// MARK: - Events

extension TrendingWidgetViewModel {
    @MainActor
    func subscribeToPodcast(_ podcast: Podcast) async {
        do {
            try await podcastService.subscribe(to: podcast).value
            podcasts?.removeAll(where: { $0.id == podcast.id })
        } catch {
            return
        }
    }
}

// MARK: - Helpers

extension TrendingWidgetViewModel {
    @MainActor
    private func refreshPodcasts() async {
        do {
            guard podcasts == nil else { return }
            let trending = podcastService.getTrending(maximumResult: Constant.maximumPodcastsToShow + Constant.maximumPodcastsFetchOverhead)
            let savedIDs = podcastService.savedPodcasts(sortingPreference: nil).first().map { $0.map(\.id) }
            let publisher = Publishers.Zip(trending, savedIDs)
                .map { trending, savedIDs in
                    trending.filter { podcast in
                        !savedIDs.contains(podcast.id)
                    }
                }

            isErrorOccurred = false
            self.podcasts = try await publisher.value
        } catch {
            isErrorOccurred = true
        }
    }
}
