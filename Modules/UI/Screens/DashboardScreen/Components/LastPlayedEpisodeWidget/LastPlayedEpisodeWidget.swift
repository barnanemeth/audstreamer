//
//  LastPlayedEpisodeWidget.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 26..
//

import SwiftUI

import Domain
import UIComponentKit

struct LastPlayedEpisodeWidget: View {

    // MARK: Dependencies

    @State private var viewModel = LastPlayedEpisodeWidgetViewModel()

    // MARK: Properties

    let episode: Episode
    let horizontalPadding: CGFloat

    // MARK: UI

    var body: some View {
        DashboardSection(
            title: "Continue",
            headerHorizontalPadding: horizontalPadding,
            contentHorizontalPadding: horizontalPadding
        ) {
            VStack {
                EpisodeHeaderComponent(episode: episode)
                    .background(Asset.Colors.surfaceElevated.swiftUIColor)

                EpisodeActionsComponent(
                    episode: episode,
                    isWatchAvailable: viewModel.isWatchAvailable,
                    isPlaying: viewModel.currentlyPlayingID == episode.id,
                    onPlayPauseTap: { await viewModel.togglePlaying(episode) },
                    onFavouriteTap: { await viewModel.toggleEpisodeFavorite(episode) },
                    onDownloadTap: { await viewModel.downloadDeleteEpisode(episode) },
                    onWatchTap: { await viewModel.toggleEpisodeIsOnWatch(episode)  }
                )
                .background(Asset.Colors.surfaceElevated.swiftUIColor)
            }
            .padding()
            .background(Asset.Colors.surfaceElevated.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 8)
        }
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
        .task(id: "LastPlayedEpisodeWidget.SubscriptionTask") { await viewModel.subscribe() }
    }
}
