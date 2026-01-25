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

    // MARK: Dependencies

    @State private var viewModel = DashboardViewModel()

    // MARK: UI

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                continueSection
                savedPodcasts
                upcomingEpisodes
                trendingPodcasts
            }
            .padding()
        }
        .navigationTitle(viewModel.screenTitle)
        .background(Asset.Colors.surfaceBase.swiftUIColor)
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
        .animation(.default, value: viewModel.savedPodcasts)
        .animation(.default, value: viewModel.trendingPodcasts)
        .task(id: "DashboardView.SubscriptionTask") { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension DashboardView {
    @ViewBuilder
    private var continueSection: some View {
        if let episode = viewModel.lastPlayedEpisode {
            section(title: "Continue") {
                VStack(spacing: 16) {
                    EpisodeHeaderComponent(episode: episode)
                        .background(Asset.Colors.surfaceBase.swiftUIColor)

                    EpisodeActionsComponent(
                        episode: episode,
                        isWatchAvailable: viewModel.isWatchAvailable,
                        isPlaying: viewModel.currentlyPlayingID == episode.id,
                        onPlayPauseTap: { await viewModel.playPauseEpisode(episode) },
                        onFavouriteTap: { await viewModel.toggleEpisodeFavorite(episode) },
                        onDownloadTap: { await viewModel.downloadDeleteEpisode(episode) },
                        onWatchTap: { await viewModel.toggleEpisodeIsOnWatch(episode)  }
                    )
                    .background(Asset.Colors.surfaceBase.swiftUIColor)
                }
                .padding()
                .background(Asset.Colors.surfaceBase.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(radius: 8)
            }
            .animation(.default, value: viewModel.lastPlayedEpisode)
        }
    }

    private var savedPodcasts: some View {
        DashboardPodcastsSection(
            podcasts: viewModel.savedPodcasts,
            onSelect: { viewModel.navigateToPodcastDetails(for: $0) },
            onSeeAllTap: { viewModel.navigateToPodcastList() },
            onBrowseTrendingTap: { },
            onSearchTap: {  }
        )
    }


    @ViewBuilder
    private var upcomingEpisodes: some View {
        if !viewModel.upcomingEpisodes.isEmpty {
            section(
                title: "Upcoming episodes",
                action: { viewModel.navigateToEpisodes(for: nil) },
            ) {
                ForEach(viewModel.upcomingEpisodes) { episode in
                    episodeItem(for: episode)
                        .id(episode)
                }
            }
        }
    }

    @ViewBuilder
    private var trendingPodcasts: some View {
        if let podcasts = viewModel.trendingPodcasts {
            section(
                title: "Trending",
                action: { },
            ) {
                ForEach(podcasts) { podcast in
                    podcastItem(for: podcast)
                        .id(podcast)
                }
            }
        } else {
            ProgressView()
                .progressViewStyle(.circular)
        }
    }

    private func podcastItem(for podcast: Podcast) -> some View {
        HStack(spacing: 16) {
            LazyImage(url: podcast.imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading) {
                Text(podcast.title)
                    .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(podcast.author ?? "")
                    .font(.captionText)
                    .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AsyncButton {
                await viewModel.toggleSubscription(for: podcast)
            } label: {
                Image(systemSymbol: podcast.isSubscribed ? .minusCircleFill : .plusCircleFill)
            }
            .foregroundStyle(podcast.isSubscribed ? Asset.Colors.State.error.swiftUIColor : Asset.Colors.accentPrimary.swiftUIColor)
        }
    }

    private func episodeItem(for episode: Episode) -> some View {
        HStack(spacing: 16) {
            LazyImage(url: episode.imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading) {
                Text(episode.podcastTitle.uppercased())
                    .font(.captionText)
                    .fontWeight(.semibold)
                    .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(episode.title)
                    .font(.captionText)
                    .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AsyncButton {
                await viewModel.playPauseEpisode(episode)
            } label: {
                Image(systemSymbol: .playpauseCircleFill)
                    .font(.h4)
            }
            .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)
        }
    }

    private func section<Content: View>(title: String, action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) -> some View {
        LazyVStack(spacing: 16) {
            Button {
                action?()
            } label: {
                HStack {
                    Text(title)
                    if action != nil {
                        Image(systemSymbol: .chevronRight)
                    }
                }
                .font(.h4)
                .fontWeight(.semibold)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(action == nil)

            content()

            Divider()
        }
    }
}
