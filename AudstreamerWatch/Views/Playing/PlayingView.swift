//
//  PlayingView.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 03..
//

import SwiftUI
import WatchKit

import Domain

import SFSafeSymbols

struct PlayingView: View {

    // MARK: Private properties

    let episode: EpisodeCommon

    @StateObject private var viewModel = PlayingViewModel()

    // MARK: UI

    var body: some View {
        ZStack {
            if let episode = viewModel.currentlyPlayingEpisode {
                episodeContent(with: episode)
            } else {
                loading
            }
        }
        .onAppear { viewModel.setEpisode(episode) }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .focusable(true)
        .overlay {
            SystemVolumeControl(origin: .local)
                .opacity(viewModel.isVolumeOverlayVisible ? 1 : 0.001)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Helpers

extension PlayingView {
    private var loading: some View {
        ProgressView()
            .progressViewStyle(.circular)
    }

    @ViewBuilder
    private func episodeContent(with episode: EpisodeCommon) -> some View {
        VStack {
            title
            Spacer()
            if #available(watchOS 26.0, *) {
                buttons
                    .buttonStyle(.glass)
            } else {
                buttons
            }
            Spacer()
            progress
        }
    }

    private var title: some View {
        Text(episode.title)
            .font(.footnote)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var buttons: some View {
        HStack {
            Button {
                viewModel.seekBackward()
            } label: {
                Image(systemSymbol: ._10ArrowTriangleheadCounterclockwise)
            }

            Button {
                viewModel.playPause()
            } label: {
                let symbol: SFSymbol = if viewModel.isPlaying {
                    .pauseCircleFill
                } else {
                    .playCircleFill
                }
                Image(systemSymbol: symbol)
            }

            Button {
                viewModel.seekForward()
            } label: {
                Image(systemSymbol: ._10ArrowTriangleheadClockwise)
            }
        }
        .font(.title)
    }

    private var progress: some View {
        VStack(spacing: .zero) {
            ProgressBar(progress: viewModel.progress)
                .animation(.default, value: viewModel.progress)

            HStack {
                Text(viewModel.elapsedTime)
                Spacer()
                Text(viewModel.remainingTime)
            }
            .font(.footnote)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
