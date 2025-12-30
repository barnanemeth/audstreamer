//
//  EpisodeSectionComponent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 28..
//

import SwiftUI

import SFSafeSymbols

struct EpisodeSectionComponent: View {

    // MARK: Properties

    let section: EpisodeSection
    let isTitleButtonVisible: Bool
    let onHeaderTap: () -> Void
    let onPlayTap: () async -> Void
    let onFavouriteTap: () async -> Void
    let onDownloadTap: () async -> Void
    let onWatchTap: () async -> Void
    let onSectionDownloadTap: () async -> Void

    // MARK: UI

    var body: some View {
        Section {
            content
        } header: {
            header
        }
        .listRowSeparator(.hidden)
    }
}

// MARK: - Helpers

extension EpisodeSectionComponent {
    @ViewBuilder
    private var content: some View {
        Button {
            onHeaderTap()
        } label: {
            EpisodeHeaderComponent(episode: section.episode)
        }
        .disabled(section.isOpened)

        if section.isOpened {
            EpisodeActionsComponent(
                episode: section.episode,
                isWatchAvailable: section.isWatchAvailable,
                onPlayTap: onPlayTap,
                onFavouriteTap: onFavouriteTap,
                onDownloadTap: onDownloadTap,
                onWatchTap: onWatchTap
            )
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let title = section.title {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                if isTitleButtonVisible {
                    AsyncButton {
                        await onSectionDownloadTap()
                    } label: {
                        let symbol: SFSymbol = if section.isDownloaded {
                            .trashFill
                        } else {
                            .arrowDownCircleFill
                        }
                        Image(systemSymbol: symbol)
                    }
                }
            }
        }
    }
}
