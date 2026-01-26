//
//  SavedPodcastsWidget.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 26..
//

import SwiftUI

import Domain
import UIComponentKit

internal import NukeUI
internal import SFSafeSymbols

struct SavedPodcastsWidget: View {

    // MARK: Constants

    private enum Constant {
        static let numberOfColumns = 3
        static let gridItems = [GridItem](repeating: GridItem(.flexible()), count: numberOfColumns)
    }

    // MARK: Dependencies

    @State private var viewModel = SavedPodcastsWidgetViewModel()

    // MARK: Properties

    let horizontalPadding: CGFloat
    let onSelect: (Podcast) -> Void
    let onSeeAllTap: () -> Void
    let onBrowseTrendingTap: () -> Void
    let onSearchTap: () -> Void

    // MARK: UI

    var body: some View {
        DashboardSection(
            title: "📚 Your Library",
            buttonTitle: "See all",
            onButtonTap: onSeeAllTap,
            headerHorizontalPadding: horizontalPadding,
            contentHorizontalPadding: horizontalPadding,
        ) {
            if let podcasts = viewModel.podcasts {
                if podcasts.isEmpty {
                    empty
                } else {
                    podcastsGrid(with: podcasts)
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .task(id: "SavedPodcastsWidget.SubscriptionTask") { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension SavedPodcastsWidget {
    private var empty: some View {
        VStack(spacing: 12) {
            emptyHeader
            emptyButtons
        }
        .padding(16)
        .background(Asset.Colors.surfaceElevated.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 8)
    }

    private var emptyHeader: some View {
        HStack(spacing: 12) {
            Image(systemSymbol: .squareStackFill)
                .resizable()
                .frame(width: 32, height: 32)

            VStack(alignment: .leading) {
                Text("Build your Library")
                    .font(.h4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Follow podcasts to see new episodes here")
                    .font(.bodySecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
        }
    }

    private var emptyButtons: some View {
        HStack(spacing: 12) {
            Button("Browse Trending") { onBrowseTrendingTap() }
                .buttonStyle(.primary(size: .small, fill: true))

            Button("Search") { onSearchTap() }
                .buttonStyle(.secondary(size: .small, fill: true))
                .fillWidth()
        }
    }

    private func podcastsGrid(with podcasts: [Podcast]) -> some View {
        LazyVGrid(columns: Constant.gridItems, spacing: 12) {
            ForEach(podcasts) { podcast in
                Button {
                    onSelect(podcast)
                } label: {
                    gridItem(for: podcast)
                }
                .id(podcast)
            }
        }
    }

    private func gridItem(for podcast: Podcast) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Color.clear
            }
            .aspectRatio(1, contentMode: .fit)
            .background {
                LazyImage(url: podcast.imageURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(podcast.title)
                .font(.captionText)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                .padding(.bottom, 12)
                .padding(.horizontal, 8)
        }
        .background(Asset.Colors.surfaceElevated.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8)
    }
}
