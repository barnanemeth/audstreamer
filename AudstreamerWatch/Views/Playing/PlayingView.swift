//
//  PlayingView.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 03..
//

import SwiftUI
import WatchKit

struct PlayingView: View {

    // MARK: Private properties

    let episode: EpisodeCommon

    @StateObject private var viewModel = PlayingViewModel()

    // MARK: UI

    var body: some View {
        VStack {
            if let episode = viewModel.currentlyPlayingEpisode {
                episodeContent(with: episode)
            } else {
                loading
            }
        }
        .onAppear { viewModel.setEpisode(episode) }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Helpers

extension PlayingView {
    var loading: some View {
        ProgressView()
            .progressViewStyle(.circular)
    }

    @ViewBuilder
    func episodeContent(with episode: EpisodeCommon) -> some View {
        Text(episode.title)
            .font(.subheadline)

        Spacer()

        HStack {
            Button("", systemImage: "backward.circle.fill") {
                viewModel.seekBackward()
            }
            .buttonStyle(.bordered)

            let systemImage = if viewModel.isPlaying {
                "pause.circle.fill"
            } else {
                "play.circle.fill"
            }
            Button("", systemImage: systemImage) {
                viewModel.playPause()
            }
            .buttonStyle(.bordered)

            Button("", systemImage: "forward.circle.fill") {
                viewModel.seekForward()
            }
            .buttonStyle(.bordered)
        }

        Spacer()

        HStack {
            ProgressView()
                .progressViewStyle(.linear)
        }
    }
}
