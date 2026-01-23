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

@Observable
final class DashboardViewModel {

    // MARK: Constants

    private enum Constant {
        static let maximumUpcomingEpisodesToShow = 5
    }

    // MARK: Dependencies

    @ObservationIgnored @Injected private var episodeService: EpisodeService
    @ObservationIgnored @Injected private var podcastService: PodcastService
    @ObservationIgnored @Injected private var navigator: Navigator
    @ObservationIgnored @Injected private var audioPlayer: AudioPlayer

    // MARK: Properties

    let screenTitle = About.appName
    private(set) var lastPlayedEpisode: Episode?
    private(set) var savedPodcasts = [Podcast]()
    private(set) var trendingPodcasts: [Podcast]?
    private(set) var upcomingEpisodes = [Episode]()
    var currentlyShowedDialogDescriptor: DialogDescriptor?

    // MARK: Private properties

    @ObservationIgnored private lazy var savedPodcastsPublisher: AnyPublisher<[Podcast], Error> = {
        podcastService.savedPodcasts().shareReplay()
    }()

    // MARK: Private properties
}

// MARK: - View model

extension DashboardViewModel: ViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeToLastPlayedEpisode() }
            taskGroup.addTask { await self.subscribeToSavedPodcasts() }
            taskGroup.addTask { await self.subscribeToTrendingPodcasts() }
            taskGroup.addTask { await self.subscribeToUpcomingEpisodes() }
        }
    }
}

// MARK: - Events

extension DashboardViewModel {
    @MainActor
    func toggleSubscription(for podcast: Podcast) async {
        do {
            if podcast.isSubscribed {
                try await podcastService.unsubscribe(from: podcast).value
            } else {
                try await podcastService.subscribe(to: podcast).value
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

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
    private func subscribeToSavedPodcasts() async {
        let publisher = savedPodcastsPublisher.replaceError(with: [])
        for await podcasts in publisher.asAsyncStream() {
            savedPodcasts = podcasts
        }
    }

    @MainActor
    private func subscribeToTrendingPodcasts() async {
        let publisher = Publishers.CombineLatest(podcastService.getTrending(maximumResult: 10), savedPodcastsPublisher)
            .map { trendingPodcasts, savedPodcasts in
                trendingPodcasts.filter { podcast in
                    !savedPodcasts.contains(where: { $0.id == podcast.id })
                }
            }
            .replaceError(with: [])

        for await podcasts in publisher.asAsyncStream() {
            trendingPodcasts = podcasts
        }
    }

    @MainActor
    func subscribeToUpcomingEpisodes() async {
        let publisher = episodeService.episodes(matching: nil)
            .map { Array($0.prefix(Constant.maximumUpcomingEpisodesToShow)) }
            .replaceError(with: [])
        for await episodes in publisher.asAsyncStream() {
            upcomingEpisodes = episodes
        }
    }

    @MainActor
    private func showErrorAlert(for error: Error) {
        currentlyShowedDialogDescriptor = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
    }
}
