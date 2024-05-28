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

    @ObservedObject private var viewModel = PlayingViewModel()

    // MAR: Init

    init(episode: EpisodeCommon) {
        viewModel.setEpisode(episode)
    }

    // MARK: UI

    var body: some View {
        NowPlayingView()
            .navigationTitle(viewModel.episode?.title ?? "")
            .onAppear(perform: { viewModel.play() })
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
