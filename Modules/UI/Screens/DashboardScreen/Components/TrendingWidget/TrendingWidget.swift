//
//  TrendingWidget.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 26..
//

import SwiftUI

import Domain
import UIComponentKit

internal import NukeUI
internal import SFSafeSymbols

struct TrendingWidget: View {

    // MARK: Dependencies

    @State private var viewModel = TrendingWidgetViewModel()

    // MARK: Properties

    let horizontalPadding: CGFloat
    let onSelect: (Podcast) -> Void
    let onSeeAllTap: () -> Void

    // MARK: UI

    var body: some View {
        DashboardSection(
            title: "🔥 Trending now",
            buttonTitle: "See all",
            onButtonTap: onSeeAllTap,
            headerHorizontalPadding: horizontalPadding,
            contentHorizontalPadding: .zero,
        ) {
            if viewModel.isErrorOccurred {
                // TODO: error
                EmptyView()
            } else if let podcasts = viewModel.podcasts {
                shelf(with: podcasts)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .animation(.default, value: viewModel.podcasts)
        .task(id: "TrendingWidget.SubscriptionTask") { await viewModel.subscribe() }
    }
}

extension TrendingWidget {
    private func shelf(with podcasts: [Podcast]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(podcasts) { podcast in
                    shelfItem(for: podcast)
                }
            }
            .padding(.horizontal, 12)
        }
        .scrollClipDisabled(true)
    }

    private func shelfItem(for podcast: Podcast) -> some View {
        Button {
            onSelect(podcast)
        } label: {
            HStack(alignment: .top, spacing: .zero) {
                image(for: podcast)

                VStack(alignment: .leading) {
                    info(for: podcast)

                    Spacer()

                    HStack {
                        Spacer()

                        AsyncButton {
                            await viewModel.subscribeToPodcast(podcast)
                        } label: {
                            Image(systemSymbol: .plusCircleFill)
                        }
                        .font(.h3)
                        .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)
                    }
                }
                .padding(8)
            }
            .background(Asset.Colors.surfaceElevated.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(radius: 8)
            .frame(width: 220, height: 100)
        }
    }

    private func image(for podcast: Podcast) -> some View {
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
    }

    private func info(for podcast: Podcast) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(podcast.title)
                .font(.captionText)
                .fontWeight(.medium)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(podcast.author ?? "")
                .font(.label)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .lineLimit(2)
        .multilineTextAlignment(.leading)
    }
}
