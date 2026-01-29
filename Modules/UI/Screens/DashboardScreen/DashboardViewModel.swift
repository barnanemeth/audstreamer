//
//  DashboardViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 21..
//

import Foundation
import Combine

import Common
import Domain

internal import Reachability
import SwiftUI

@Observable
final class DashboardViewModel {

    // MARK: Constants

    private enum Constant {
        static let maximumLatestEpisodesToShow = 5
    }

    // MARK: Dependencies

    @ObservationIgnored @Injected private var episodeService: EpisodeService
    @ObservationIgnored @Injected private var podcastService: PodcastService
    @ObservationIgnored @Injected private var navigator: Navigator
    @ObservationIgnored @Injected private var audioPlayer: AudioPlayer

    // MARK: Properties

    let screenTitle = About.appName
    private(set) var lastPlayedEpisode: Episode?
    private(set) var latestEpisodes = [Episode]()
    var currentlyShowedDialogDescriptor: DialogDescriptor?
}

// MARK: - View model

extension DashboardViewModel: ViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeToLastPlayedEpisode() }
            taskGroup.addTask { await self.subscribeToLatestEpisodes() }
        }
    }
}

// MARK: - Events

extension DashboardViewModel {
    @MainActor
    func navigateToEpisodes(for podcast: Podcast?) {
        navigator.navigate(to: .episodeList(podcast: podcast), method: .push)
    }

    @MainActor
    func playPauseEpisode(_ episode: Episode) async {
        do {
            let currentlyPlayingEpisodeID = try await audioPlayer.getCurrentPlayingAudioInfo().map(\.?.id).value
            if currentlyPlayingEpisodeID == episode.id {
                try await audioPlayer.pause().value
            } else {
                try await audioPlayer.insert(episode, playImmediately: true).value
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

    @MainActor
    func navigateToPodcastDetails(for podcast: Podcast) {
        navigator.navigate(to: .podcastDetails(podcast: podcast, namespace: nil), method: .push)
    }

    @MainActor
    func navigateToPodcastList() {
        navigator.changeTab(to: .podcasts)
    }

    @MainActor
    func navigateToTrending() {
        navigator.changeTab(to: .search, values: [AppNavigationDestination.SearchMode.trending])
    }

    @MainActor
    func navigateToSearch() {
        navigator.changeTab(to: .search, values: [AppNavigationDestination.SearchMode.search])
    }
}

// MARK: - Helpers

extension DashboardViewModel {
    @MainActor
    private func subscribeToLastPlayedEpisode() async {
        let publisher = episodeService.lastPlayedEpisode().replaceError(with: nil)
        for await episode in publisher.asAsyncStream() {
            lastPlayedEpisode = episode
        }
    }

    @MainActor
    func subscribeToLatestEpisodes() async {
        let publisher = episodeService.episodes(matching: nil)
            .map { Array($0.prefix(Constant.maximumLatestEpisodesToShow)) }
            .replaceError(with: [])
        for await episodes in publisher.asAsyncStream() {
            latestEpisodes = episodes
        }
    }

    @MainActor
    private func showErrorAlert(for error: Error) {
        currentlyShowedDialogDescriptor = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
    }
}
