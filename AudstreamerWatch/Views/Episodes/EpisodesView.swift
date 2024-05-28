//
//  EpisodesView.swift
//  AudstreamerWatch Watch App
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import SwiftUI

struct EpisodesView: View {

    // MARK: Private properties

    @ObservedObject private var viewModel = EpisodesViewModel()
    private let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""

    // MARK: UI

    var body: some View {
        NavigationStack {
            if viewModel.episodes.isEmpty {
                Text(L10n.noEpisodes)
            } else {
                List {
                    ForEach(viewModel.episodes, id: \.id) { episode in
                        NavigationLink(episode.title, destination: { PlayingView(episode: episode) })
                            .foregroundColor(episode.isDownloaded ? .green : .red)
                            .disabled(!episode.isDownloaded)
                    }
                }
                .navigationTitle(displayName)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
