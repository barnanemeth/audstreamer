//
//  PlayerBottomWidget.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 14..
//

import SwiftUI

import Common
import Domain
import UIComponentKit

internal import NukeUI
internal import SFSafeSymbols

@MainActor
struct PlayerBottomWidget: View {

    // MARK: Constants

    private enum Constant {
        static let thumbnailSize = CGSize(width: 36, height: 36)
    }

    // MARK: Dependencies

    @Bindable private var viewModel: PlayerViewModel

    // MARK: Properties

    let onTap: () -> Void

    // MARK: Init

    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        _viewModel = Bindable(Resolver.resolve())
    }

    // MARK: UI

    var body: some View {
        HStack {
            if let episode = viewModel.episode {
                playingContent(for: episode)
            } else {
                nonPlayingContent
            }
        }
        .padding(4)
        .disabled(!viewModel.isEnabled)
        .task(id: "PlayerBottomWidget.SubscriptionTask") { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension PlayerBottomWidget {
    @ViewBuilder
    private func playingContent(for episode: Episode) -> some View {
        HStack {
            thumbnail(for: episode)
            info(for: episode)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }

        playPauseButton
    }

    private var nonPlayingContent: some View {
        Color.clear
    }

    @ViewBuilder
    private func thumbnail(for episode: Episode) -> some View {
        if let thumbnail = episode.thumbnail {
            LazyImage(url: thumbnail) { state in
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            Circle()
                .redacted(reason: [.placeholder])
                .opacity(0.5)
                .frame(width: 36, height: 36)
        }
    }

    @ViewBuilder
    private func info(for episode: Episode) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(episode.podcastTitle.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(episode.title)
                .font(.captionText)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(viewModel.elapsedTimeText)
                .font(.captionText)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .lineLimit(1)
    }

    private var playPauseButton: some View {
        Button {
            viewModel.playPlause()
        } label: {
            let symbol: SFSymbol = if viewModel.isPlaying {
                .pauseCircleFill
            } else {
                .playCircleFill
            }
            Image(systemSymbol: symbol)
                .font(.system(size: 30))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)
        }
    }
}
