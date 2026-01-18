//
//  PlayerBottomWidget.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 14..
//

import SwiftUI

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

    @State private var viewModel = PlayerViewModel()

    // MARK: Properties

    let onTap: () -> Void

    // MARK: UI

    var body: some View {
        HStack {
            HStack {
                thumbnail
                info
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            playPauseButton
        }
        .padding(4)
        .disabled(!viewModel.isEnabled)
        .task(id: "PlayerBottomWidget.SubscriptionTask") { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension PlayerBottomWidget {
    @ViewBuilder
    private var thumbnail: some View {
        if let thumbnail = viewModel.episode?.thumbnail {
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
        }
    }

    private var info: some View {
        VStack(alignment: .leading) {
            Text(viewModel.episode?.title ?? "")
                .lineLimit(1)
            Text(viewModel.elapsedTimeText)
        }
        .font(.caption2)
        .foregroundStyle(Asset.Colors.label.swiftUIColor)
        .frame(maxWidth: .infinity)
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
                .foregroundStyle(Asset.Colors.primary.swiftUIColor)
        }
    }
}
