//
//  DashboardView.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 21..
//

import SwiftUI

import Domain
import UIComponentKit

internal import NukeUI
internal import SFSafeSymbols

struct DashboardView: View {

    // MARK: Constants

    private enum Constant {
        static let defaultHorizontalPadding: CGFloat = 16
    }

    // MARK: Dependencies

    @State private var viewModel = DashboardViewModel()

    // MARK: UI

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                continueSection
                savedPodcasts
                trendingPodcasts
                latestEpisodes
            }
            .padding(.vertical)
        }
        .navigationTitle(viewModel.screenTitle)
        .background(Asset.Colors.surfaceBase.swiftUIColor)
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
        .animation(.default, value: viewModel.lastPlayedEpisode)
        .task(id: "DashboardView.SubscriptionTask") { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension DashboardView {
    @ViewBuilder
    private var continueSection: some View {
        if let episode = viewModel.lastPlayedEpisode {
            LastPlayedEpisodeWidget(episode: episode, horizontalPadding: Constant.defaultHorizontalPadding)
                .geometryGroup()
        }
    }

    private var savedPodcasts: some View {
        SavedPodcastsWidget(
            horizontalPadding: Constant.defaultHorizontalPadding,
            onSelect: { viewModel.navigateToPodcastDetails(for: $0) },
            onSeeAllTap: { viewModel.navigateToPodcastList() },
            onBrowseTrendingTap: { viewModel.navigateToTrending() },
            onSearchTap: { viewModel.navigateToSearch() }
        )
        .geometryGroup()
    }

    private var trendingPodcasts: some View {
        TrendingWidget(
            horizontalPadding: Constant.defaultHorizontalPadding,
            onSelect: { viewModel.navigateToPodcastDetails(for: $0) },
            onSeeAllTap: { viewModel.navigateToTrending() }
        )
        .geometryGroup()
    }

    @ViewBuilder
    private var latestEpisodes: some View {
        if !viewModel.latestEpisodes.isEmpty {
            LatestEpisodesWidget(
                episodes: viewModel.latestEpisodes,
                horizontalPadding: Constant.defaultHorizontalPadding,
                onSeeAllTap: { viewModel.navigateToEpisodes(for: nil) }
            )
            .geometryGroup()
        }
    }
}
