//
//  LastPlayedEpisodeWidgetViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 26..
//

import Foundation
import Combine

import Common
import Domain

internal import Reachability

@Observable
final class LastPlayedEpisodeWidgetViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var episodeService: EpisodeService
    @ObservationIgnored @Injected private var audioPlayer: AudioPlayer
    @ObservationIgnored @Injected private var socket: Socket
    @ObservationIgnored @Injected private var cloud: Cloud

    // MARK: Properties

    private(set) var currentlyPlayingID: String?
    private(set) var isWatchAvailable = false
    var currentlyShowedDialogDescriptor: DialogDescriptor?

    // MARK: Private properties

    @ObservationIgnored private var currentlyPlayingIDPublisher: AnyPublisher<String?, Error> {
        Publishers.CombineLatest(audioPlayer.getCurrentPlayingAudioInfo().map(\.?.id), audioPlayer.isPlaying())
            .map { $1 ? $0 : nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - View model

extension LastPlayedEpisodeWidgetViewModel: ViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeCurrentlyPlayingIDPublisher() }
            taskGroup.addTask { await self.subscribeToWatchAvailability() }
        }
    }
}

// MARK: - Events

extension LastPlayedEpisodeWidgetViewModel {
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
}


// MARK: - Helpers

extension LastPlayedEpisodeWidgetViewModel {
    @MainActor
    private func subscribeCurrentlyPlayingIDPublisher() async {
        for await id in currentlyPlayingIDPublisher.replaceError(with: nil).asAsyncStream() {
            currentlyPlayingID = id
        }
    }

    @MainActor
    private func subscribeToWatchAvailability() async {
        @Injected var watchConnectivityService: WatchConnectivityService
        for await isAvailable in watchConnectivityService.isAvailable().replaceError(with: false).asAsyncStream() {
            isWatchAvailable = isAvailable
        }
    }

    private func pausePlaying() async throws {
        try await withThrowingTaskGroup { taskGroup in
            taskGroup.addTask { try await self.audioPlayer.pause().value }
            taskGroup.addTask { try await self.socket.sendPlaybackCommand(.pause).value }

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
                let currentEpisodeSocketData = CurrentEpisodeSocketData(episodeID: episode.id, playImmediately: true)
                try await self.socket.sendCurrentEpisode(currentEpisodeSocketData).value
            }

            try await taskGroup.waitForAll()
        }
    }

    @MainActor
    private func downloadEpisodes(_ episodes: [Episode]) async {
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
    private func showErrorAlert(for error: Error) {
        currentlyShowedDialogDescriptor = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
    }
}
