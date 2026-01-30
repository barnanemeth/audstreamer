//
//  LatestEpisodesWidgetViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 26..
//

import Foundation
import Combine

import Common
import Domain

@Observable
final class LatestEpisodesWidgetViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var audioPlayer: AudioPlayer
    @ObservationIgnored @Injected private var socket: Socket

    // MARK: Properties

    private(set) var currentlyPlayingID: String?

    // MARK: Private properties

    @ObservationIgnored private var currentlyPlayingIDPublisher: AnyPublisher<String?, Error> {
        Publishers.CombineLatest(audioPlayer.getCurrentPlayingAudioInfo().map(\.?.id), audioPlayer.isPlaying())
            .map { $1 ? $0 : nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - View model

extension LatestEpisodesWidgetViewModel: ViewModel {
    func subscribe() async {
        await subscribeCurrentlyPlayingIDPublisher()
    }
}

// MARK: - Events

extension LatestEpisodesWidgetViewModel {
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
            return
        }
    }
}

// MARK: - Helpers

extension LatestEpisodesWidgetViewModel {
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
}
