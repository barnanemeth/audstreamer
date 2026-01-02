//
//  EpisodesView.swift
//  AudstreamerWatch Watch App
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

//import SwiftUI
//
//struct EpisodesView: View {
//
//    // MARK: Private properties
//
//    @StateObject private var viewModel = EpisodesViewModel()
//
//    // MARK: UI
//
//    var body: some View {
//        List {
//            ForEach(viewModel.episodes, id: \.self) { data in
//                NavigationLink {
//                    PlayingView(episode: data.episode)
//                } label: {
//                    EpisodeRow(data: data)
//                }
//                .disabled(!data.episode.isDownloaded)
//            }
//        }
//        .navigationTitle(viewModel.title)
//        .navigationBarTitleDisplayMode(.inline)
//        .overlay { emptyOverlay }
//    }
//}
//
//// MARK: - Helpers
//extension EpisodesView {
//    @ViewBuilder
//    private var emptyOverlay: some View {
//        if viewModel.episodes.isEmpty {
//            VStack(spacing: 16) {
//                Image(systemName: "square.stack")
//                    .font(.largeTitle)
//                
//                Text(L10n.noEpisodes)
//            }
//        }
//    }
//}
