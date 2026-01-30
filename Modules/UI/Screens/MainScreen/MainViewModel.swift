//
//  MainViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 15..
//

import Foundation
import Combine
import SwiftUI

import Common
import Domain

@Observable
final class MainViewModel: ViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var audioPlayer: AudioPlayer
    @ObservationIgnored @Injected private var navigator: Navigator
    @ObservationIgnored @Injected private var episodeService: EpisodeService

    // MARK: Properties

    private(set) var isPlayerBottomWidgetVisible = false
}

// MARK: - View model

extension MainViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.startUpdating() }
            taskGroup.addTask { await self.startUpdating() }
            taskGroup.addTask { await self.updatePlayerBottomWidgetVisibility() }
        }
    }
}

// MARK: - Actions

extension MainViewModel {
    @MainActor
    func showDownloads() {
        navigator.navigate(to: .downloads, method: .managedSheet)
    }

    @MainActor
    func showPlayerScreen() {
        navigator.navigate(to: .player(detents: [.medium]), method: .sheet)
    }
}

// MARK: - Helpers

extension MainViewModel {
    @MainActor
    private func updatePlayerBottomWidgetVisibility() async {
        let publisher = audioPlayer.getCurrentPlayingAudioInfo()
            .replaceError(with: nil)
            .map { $0 != nil }
            .removeDuplicates()
        for await isVisible in publisher.bufferedValues {
            isPlayerBottomWidgetVisible = isVisible
        }
    }

    @MainActor
    private func startUpdating() async {
        try? await episodeService.startUpdating().value
    }
}
