//
//  PodcastDetailsView.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import SwiftUI

import Domain
import UIComponentKit

internal import NukeUI
internal import SFSafeSymbols

struct PodcastDetailsView: View {

    // MARK: Dependencies

    @State private var viewModel = PodcastDetailsViewModel()

    // MARK: Properties

    let podcast: Podcast
    let transitionNamesapce: Namespace.ID?

    // MARK: UI

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                image
                content
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Helpers

extension PodcastDetailsView {
    private var image: some View {
        ZStack {
            Color.clear
        }
        .aspectRatio(1, contentMode: .fit)
        .background {
            LazyImage(url: podcast.imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .apply {
                if let transitionNamesapce {
                    $0.navigationTransition(.zoom(sourceID: podcast, in: transitionNamesapce))
                } else {
                   $0
                }
            }
        }
        .clipped()
    }

    private var content: some View {
        VStack(spacing: 16) {
            titleSection
            Divider()

            Button {
                viewModel.navigateToEpisodes(with: podcast)
            } label: {
                Text("Episodes")
            }
            .buttonStyle(.primary())
        }
        .padding()
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(podcast.title)
                .font(.h4)

            Text(podcast.description ?? "")
                .font(.bodyText)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
