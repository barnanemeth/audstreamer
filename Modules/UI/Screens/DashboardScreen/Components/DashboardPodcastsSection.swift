//
//  DashboardPodcastsSection.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 24..
//

import SwiftUI

import Domain
import UIComponentKit

internal import SFSafeSymbols
internal import NukeUI

struct DashboardPodcastsSection: View {

    // MARK: Constants

    private enum Constant {
        static let numberOfColumns = 3
        static let gridItems = [GridItem](repeating: GridItem(.flexible()), count: numberOfColumns)
    }

    // MARK: Properties

    let podcasts: [Podcast]
    let onSelect: (Podcast) -> Void
    let onSeeAllTap: () -> Void
    let onBrowseTrendingTap: () -> Void
    let onSearchTap: () -> Void

    // MARK: Private properties

    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    private var backgroundColor: Color {
        switch colorScheme {
        case .light: .white
        case .dark: .gray.opacity(0.1)
        @unknown default: .white
        }
    }

    // MARK: UI

    var body: some View {
        VStack(spacing: 16) {
            header
            if podcasts.isEmpty {
                empty
            } else {
                podcastGrid
            }
        }
    }
}

// MARK: - Helpers

extension DashboardPodcastsSection {
    private var header: some View {
        HStack {
            Text("Your Library")
                .font(.h4)
                .fontWeight(.semibold)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)

            Spacer()

            Button {
                onSeeAllTap()
            } label: {
                Text("See all")
                    .font(.bodySecondaryText)
                    .fontWeight(.medium)
                    .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)

                Image(systemSymbol: .chevronRight)
                    .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
            }
        }
    }

    private var podcastGrid: some View {
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
        }
        .padding(12)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 8)
    }

    private var empty: some View {
        VStack {
            emptyHeader
            emptyButtons
        }
        .padding(16)
        .background(Asset.Colors.surfaceBase.swiftUIColor)
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

                Text("Follow podcasts to see new episodes here")
                    .font(.bodySecondaryText)
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
}
