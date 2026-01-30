//
//  PodcastDetailsView.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import SwiftUI

import Domain
import UIComponentKit

internal import NukeUI
internal import SFSafeSymbols

struct PodcastDetailsView: View {

    // MARK: Dependencies

    @State private var viewModel = PodcastDetailsViewModel()

    // MARK: Properties

    let podcast: Podcast
    let transitionNamesapce: Namespace.ID?

    // MARK: Private properties

    private var updatedPodcast: Podcast {
        viewModel.podcast ?? podcast
    }

    // MARK: UI

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                image
                content
            }
        }
        .ignoresSafeArea(edges: .top)
        .animation(.default, value: viewModel.episodes)
        .dialog(descriptor: $viewModel.currentlyShowingDialogDescriptor)
        .task(id: "PodcastDetailsView.SubscriptionTask") { await viewModel.subscribe(with: podcast) }
    }
}

// MARK: - Helpers

extension PodcastDetailsView {
    private var image: some View {
        ZStack {
            Color.clear
        }
        .aspectRatio(1, contentMode: .fit)
        .background {
            LazyImage(url: updatedPodcast.imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .apply {
                if let transitionNamesapce {
                    $0.navigationTransition(.zoom(sourceID: podcast, in: transitionNamesapce))
                } else {
                   $0
                }
            }
        }
        .clipped()
    }

    private var content: some View {
        VStack(spacing: 20) {
            titleSection
            buttons
            episodesInfo
            Divider()
            episodeList
        }
        .padding()
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(updatedPodcast.title)
                .font(.h4)

            if let description = viewModel.descriptionAttributedString {
                Text(description)
                    .font(.bodySecondaryText)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttons: some View {
        HStack(spacing: 8) {
            AsyncButton(updatedPodcast.isSubscribed ? "Unsubscribe" : "Subscribe") {
                await viewModel.toggleSubscription()
            }
            .frame(maxWidth: .infinity)
            .apply {
                if updatedPodcast.isSubscribed {
                    $0.buttonStyle(.secondary(size: .medium, fill: true, icon: Image(systemSymbol: .minusCircleFill)))
                } else {
                    $0.buttonStyle(.primary(size: .medium, fill: true, icon: Image(systemSymbol: .plusCircleFill)))
                }
            }
            .contentTransition(.symbolEffect(.replace))

            AsyncButton(viewModel.isDownloaded ? "Delete" : "Download") {
                await viewModel.download()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(
                .secondary(
                    size: .medium,
                    fill: true,
                    icon: Image(systemSymbol: viewModel.isDownloaded ? .arrowDownCircleBadgeXmarkFill : .arrowDownCircleFill
                )
                )
            )
        }
    }

    @ViewBuilder
    private var episodesInfo: some View {
        if let (count, duration) = viewModel.allEpisodesInfo {
            Text("\(count) episodes · \(duration.formatted(.units(allowed: [.days, .hours])))")
                .font(.bodySecondaryText)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var episodeList: some View {
        if let episodes = viewModel.episodes {
            VStack(spacing: 16) {
                epsidodeListHeader
                LazyVStack(spacing: 12) {
                    ForEach(episodes) { episode in
                        lisItem(for: episode)
                            .id(episode)

                        Divider()
                            .padding(.horizontal, 52)
                    }
                }
            }
        }
    }

    private var epsidodeListHeader: some View {
        HStack {
            Text("Latest episodes")
                .font(.h4)
                .fontWeight(.semibold)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)

            Spacer()

            Button {
                viewModel.navigateToEpisodes()
            } label: {
                Text("See all")
                Image(systemSymbol: .chevronRight)
            }
            .buttonStyle(.text())
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
