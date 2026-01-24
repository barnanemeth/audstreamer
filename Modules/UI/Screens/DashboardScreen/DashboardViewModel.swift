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

    // Note: temporary
    // MARK: Episode

    private(set) var currentlyPlayingID: String?
    private(set) var isWatchAvailable = false
}

// MARK: - View model

extension DashboardViewModel: ViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeToLastPlayedEpisode() }
            taskGroup.addTask { await self.subscribeToSavedPodcasts() }
            taskGroup.addTask { await self.subscribeToTrendingPodcasts() }
            taskGroup.addTask { await self.subscribeToUpcomingEpisodes() }
            taskGroup.addTask { await self.subscribeCurrentlyPlayingIDPublisher() }
            taskGroup.addTask { await self.subscribeToWatchAvailability() }
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

// Note: temporary
// MARK: - Episode

extension DashboardViewModel {
    @ObservationIgnored private var currentlyPlayingIDPublisher: AnyPublisher<String?, Error> {
        Publishers.CombineLatest(audioPlayer.getCurrentPlayingAudioInfo().map(\.?.id), audioPlayer.isPlaying())
            .map { $1 ? $0 : nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    @MainActor
    func subscribeCurrentlyPlayingIDPublisher() async {
        for await id in currentlyPlayingIDPublisher.replaceError(with: nil).asAsyncStream() {
            currentlyPlayingID = id
        }
    }

    @MainActor
    func subscribeToWatchAvailability() async {
        @Injected var watchConnectivityService: WatchConnectivityService
        for await isAvailable in watchConnectivityService.isAvailable().replaceError(with: false).asAsyncStream() {
            isWatchAvailable = isAvailable
        }
    }

    @MainActor
    func togglePlaying(_ episode: Episode) async {
        do {
            let currentlyPlayingID = try await currentlyPlayingIDPublisher.value
            if currentlyPlayingID == episode.id {
                try await pausePlaying()
            } else {
                try await playEpisode(episode)
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

    @MainActor
    func toggleEpisodeFavorite(_ episode: Episode) async {
        do {
            let isFavorite = !episode.isFavourite
            try await withThrowingTaskGroup { taskGroup in
                taskGroup.addTask {
                    try await self.episodeService.setFavorite(episode, isFavorite: isFavorite).value
                }

                taskGroup.addTask {
                    @Injected var cloud: Cloud
                    try await cloud.setFavorite(isFavorite, for: episode.id).value
                }

                try await taskGroup.waitForAll()
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

    func downloadDeleteEpisode(_ episode: Episode) async {
        if episode.isDownloaded {
            try? await episodeService.deleteDownload(for: episode).value
        } else {
            await downloadEpisodesIfPossible([episode])
        }
    }

    @MainActor
    func toggleEpisodeIsOnWatch(_ episode: Episode) async {
        do {
            let isOnWatch = !episode.isOnWatch
            if isOnWatch {
                try await episodeService.sendToWatch(episode).value
            } else {
                try await episodeService.removeFromWatch(episode).value
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

    private func pausePlaying() async throws {
        try await withThrowingTaskGroup { taskGroup in
            taskGroup.addTask { try await self.audioPlayer.pause().value }
            taskGroup.addTask {
                @Injected var socket: Socket
                try await socket.sendPlaybackCommand(.pause).value
            }

            try await taskGroup.waitForAll()
        }
    }

    private func playEpisode(_ episode: Episode) async throws {
        try await withThrowingTaskGroup { taskGroup in
            taskGroup.addTask {
                let currentPlayingAudioInfo = try await self.audioPlayer.getCurrentPlayingAudioInfo().value
                if currentPlayingAudioInfo?.id == episode.id {
                    try await self.audioPlayer.play().value
                } else {
                    try await self.audioPlayer.insert(episode, playImmediately: true).value
                }
            }

            taskGroup.addTask {
                @Injected var socket: Socket
                let currentEpisodeSocketData = CurrentEpisodeSocketData(episodeID: episode.id, playImmediately: true)
                try await socket.sendCurrentEpisode(currentEpisodeSocketData).value
            }

            try await taskGroup.waitForAll()
        }
    }

    @MainActor
    private func downloadEpisodesIfPossible(_ episodes: [Episode]) async {
        if isOnlyCellularAvailable() {
            await presentCellularWarningAlert(for: episodes)
        } else {
            await downloadEpisodes(episodes)
        }
    }

    private func isOnlyCellularAvailable() -> Bool {
        @OptionalInjected var reachability: Reachability?
        return reachability?.connection == .cellular
    }

    @MainActor
    func downloadEpisodes(_ episodes: [Episode]) async {
        await withTaskGroup { taskGroup in
            episodes.forEach { episode in
                taskGroup.addTask { try? await self.episodeService.download(episode).value }
            }
            await taskGroup.waitForAll()
        }
    }

    @MainActor
    private func presentCellularWarningAlert(for episodes: [Episode]) async {
        do {
            let size: Int = try await withThrowingTaskGroup { taskGroup in
                episodes.forEach { episode in
                    taskGroup.addTask { try await URLHelper.contentLength(of: episode.mediaURL) }
                }

                return try await taskGroup.reduce(.zero, +)
            }
            presentCellularWarningAlert(for: episodes, contentLength: size)
        } catch {
            showErrorAlert(for: error)
        }
    }

    private func presentCellularWarningAlert(for episodes: [Episode], contentLength: Int?) {
        currentlyShowedDialogDescriptor = DialogDescriptor(
            title: L10n.download,
            message: getCellularWarningMessage(episodesCount: episodes.count, contentLength: contentLength),
            type: .alert,
            actions: [
                DialogAction(
                    title: L10n.laterOnWifi,
                    type: .normal
                ),
                DialogAction(
                    title: L10n.download,
                    type: .normal,
                    action: { [unowned self] in Task { @MainActor in await downloadEpisodes(episodes) } }
                )
            ]
        )
    }

    private func getCellularWarningMessage(episodesCount: Int, contentLength: Int?) -> String {
        var message = ""
        if let contentLength = contentLength {
            message += L10n.downloadSize(
                episodesCount,
                NumberFormatterHelper.getFormattedContentSize(from: contentLength)
            )
            message += " "
        }
        message += L10n.downloadCellularWarningMessage
        return message
    }
}
