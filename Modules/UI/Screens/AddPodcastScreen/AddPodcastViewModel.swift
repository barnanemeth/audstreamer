//
//  NewPodcastViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import Foundation

import Common
import Domain

@Observable
final class AddPodcastViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var podcastService: PodcastService

    // MARK: Properties

    var feedURL = ""
    private(set) var isLoading = false
}

// MARK: - View model

extension AddPodcastViewModel: ViewModel {
    func subscribe() async { }
}

// MARK: - Events

extension AddPodcastViewModel {
    @MainActor
    func addPodcast() async {
        guard let url = URL(string: feedURL) else { return }
        do {
            try await podcastService.addPodcastFeed(url).value
        } catch {
            print(error)
        }
    }
}
