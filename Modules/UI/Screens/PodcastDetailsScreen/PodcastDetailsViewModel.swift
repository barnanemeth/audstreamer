//
//  PodcastDetailsViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import Foundation
import Combine
import SwiftUI

import Common
import Domain
import UIComponentKit

@Observable
final class PodcastDetailsViewModel {

    // MARK: Constants

    private enum Constant {
        static let maximumEpisodesToShow = 5
    }

    // MARK: Dependencies

    @ObservationIgnored @Injected private var podcastService: PodcastService
    @ObservationIgnored @Injected private var episodeService: EpisodeService
    @ObservationIgnored @Injected private var audioPlayer: AudioPlayer
    @ObservationIgnored @Injected private var socket: Socket
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    private(set) var podcast: Podcast?
    private(set) var descriptionAttributedString: AttributedString?
    private(set) var episodes: [Episode]?
    private(set) var allEpisodesInfo: (count: Int, duration: Duration)?
    private(set) var currentlyPlayingID: String?
    private(set) var isDownloaded = false
    var currentlyShowingDialogDescriptor: DialogDescriptor?

    // MARK: Private properties

    @ObservationIgnored private var currentlyPlayingIDPublisher: AnyPublisher<String?, Error> {
        Publishers.CombineLatest(audioPlayer.getCurrentPlayingAudioInfo().map(\.?.id), audioPlayer.isPlaying())
            .map { $1 ? $0 : nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

}

// MARK: - View model

extension PodcastDetailsViewModel {
    func subscribe(with podcast: Podcast) async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeToPodcast(podcast) }
            taskGroup.addTask { await self.subscribeToEpisodes(podcast) }
            taskGroup.addTask { await self.updateIsDownloaded(for: podcast) }
            taskGroup.addTask { await self.subscribeCurrentlyPlayingIDPublisher() }
        }
    }
}

// MARK: - Events

extension PodcastDetailsViewModel {
    @MainActor
    func toggleSubscription() async {
        guard let podcast else { return }
        do {
            if podcast.isSubscribed {
                try await podcastService.unsubscribe(from: podcast).value
                self.podcast?.isSubscribed = false
            } else {
                try await podcastService.subscribe(to: podcast).value
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

    @MainActor
    func download() async {
        // TODO: implement
    }

    @MainActor
    func navigateToEpisodes(with podcast: Podcast) {
        navigator.navigate(to: .episodeList(podcast: podcast), method: .push)
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
    func navigateToEpisodes() {
        navigator.navigate(to: .episodeList(podcast: podcast), method: .push)
    }
}

// MARK: - Helpers

extension PodcastDetailsViewModel {
    @MainActor
    private func subscribeToPodcast(_ podcast: Podcast) async {
        let publisher = podcastService.podcast(id: podcast.id).replaceError(with: nil).unwrap()
        for await podcast in publisher.bufferedValues {
            self.podcast = podcast
            descriptionAttributedString = attributedString(from: podcast.description ?? "")
        }
    }

    @MainActor
    private func subscribeToEpisodes(_ podcast: Podcast) async {
        let publisher = episodeService.episodes(matching: EpisodeQueryAttributes(podcastID: podcast.id)).replaceError(with: []).removeDuplicates()
        for await episodes in publisher.bufferedValues {
            if episodes.isEmpty {
                allEpisodesInfo = nil
                self.episodes = nil
            } else {
                allEpisodesInfo = (episodes.count, Duration(secondsComponent: Int64(episodes.map(\.duration).reduce(0, +)), attosecondsComponent: .zero))
                self.episodes = Array(episodes.prefix(Constant.maximumEpisodesToShow))
            }
        }
    }

    @MainActor
    private func updateIsDownloaded(for podcast: Podcast) async {
        let query = EpisodeQueryAttributes(podcastID: podcast.id)
        let publisher = episodeService.episodes(matching: query)
            .map { episodes in
                episodes.allSatisfy { $0.isDownloaded }
            }
            .replaceError(with: false)
        for await isDownloaded in publisher.bufferedValues {
            self.isDownloaded = isDownloaded
        }
    }

    @MainActor
    private func showErrorAlert(for error: Error) {
        currentlyShowingDialogDescriptor = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
    }

    @MainActor
    private func subscribeCurrentlyPlayingIDPublisher() async {
        for await id in currentlyPlayingIDPublisher.replaceError(with: nil).bufferedValues {
            currentlyPlayingID = id
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

    func attributedString(from html: String) -> AttributedString {
        let htmlData = NSString(string: html).data(using: String.Encoding.unicode.rawValue)
        let options = [
            NSAttributedString.DocumentReadingOptionKey.documentType:
                NSAttributedString.DocumentType.html
        ]
        let nsAttributedString = try? NSMutableAttributedString(
            data: htmlData ?? Data(),
            options: options,
            documentAttributes: nil
        )
        guard let nsAttributedString else { return AttributedString(html) }

        var attributedString = AttributedString(nsAttributedString)

        attributedString.font = Font.bodySecondaryText
        attributedString.foregroundColor = Asset.Colors.labelPrimary.swiftUIColor

        return attributedString
    }
}
