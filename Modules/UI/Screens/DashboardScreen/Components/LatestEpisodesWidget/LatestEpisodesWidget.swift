//
//  LatestEpisodesWidget.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 26..
//

import SwiftUI

import Domain
import UIComponentKit

internal import SFSafeSymbols

struct LatestEpisodesWidget: View {

    // MARK: Dependencies

    @State private var viewModel = LatestEpisodesWidgetViewModel()

    // MARK: Properties

    let episodes: [Episode]
    let horizontalPadding: CGFloat
    let onSeeAllTap: () -> Void

    // MARK: UI

    var body: some View {
        DashboardSection(
            title: "Latest episodes",
            buttonTitle: "See all",
            onButtonTap: onSeeAllTap,
            headerHorizontalPadding: horizontalPadding,
            contentHorizontalPadding: horizontalPadding,
        ) {
            list
        }
        .task(id: "LatestEpisodesWidget.SubscriptionTask") { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension LatestEpisodesWidget {
    private var list: some View {
        LazyVStack(spacing: 12) {
            ForEach(episodes) { episode in
                lisItem(for: episode)
                    .id(episode)

                Divider()
            }
        }
    }

    private func lisItem(for episode: Episode) -> some View {
        HStack(spacing: 16) {
            EpisodeHeaderComponent(episode: episode, shouldShowIndicators: false)

            AsyncButton {
                await viewModel.togglePlaying(episode)
            } label: {
                let symbol: SFSymbol = if viewModel.currentlyPlayingID == episode.id {
                    .pauseCircleFill
                } else {
                    .playCircleFill
                }
                Image(systemSymbol: symbol)
                    .font(.system(size: 32, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
            }
            .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)
        }
    }
}
