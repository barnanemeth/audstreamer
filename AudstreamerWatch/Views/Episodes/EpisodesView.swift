//
//  EpisodesView.swift
//  AudstreamerWatch Watch App
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import SwiftUI

struct EpisodesView: View {

    // MARK: Private properties

    @StateObject private var viewModel = EpisodesViewModel()

    // MARK: UI

    var body: some View {
        NavigationStack {
            if viewModel.episodes.isEmpty {
                Text(L10n.noEpisodes)
            } else {
                list
            }
        }
    }
}

// MARK: - Helpers
extension EpisodesView {
    var list: some View {
        List {
            ForEach(viewModel.episodes, id: \.id) { episode in
                NavigationLink(episode.title) {
                    PlayingView(episode: episode)
                }
                .foregroundColor(episode.isDownloaded ? .green : .red)
                .disabled(!episode.isDownloaded)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
