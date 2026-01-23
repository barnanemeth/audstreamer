//
//  PodcastListView.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import SwiftUI

internal import SFSafeSymbols

struct PodcastListView: View {

    // MARK: Constants

    private enum Constants {
        static let gridSpacing: CGFloat = 16
        static let gridColumns = [GridItem(.flexible()), GridItem(.flexible())]
    }

    // MARK: Dependencies

    @State private var viewModel = PodcastListViewModel()

    // MARK: Private properties

    @Namespace private var transitionNamespace: Namespace.ID
    @Environment(\.navigator) private var navigator

    // MARK: UI

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Constants.gridColumns, spacing: Constants.gridSpacing) {
                ForEach(viewModel.podcasts) { podcast in
                    Button {
                        viewModel.showPodcastDetails(for: podcast, namesapce: transitionNamespace)
                    } label: {
                        PodcastCard(podcast: podcast, transitionNamespace: transitionNamespace)
                    }
                    .id(podcast)
                }
            }
            .padding()
        }
        .listStyle(.plain)
        .background(Color(uiColor: UIColor.systemGroupedBackground))
        .overlay { emptyView }
        .animation(.default, value: viewModel.podcasts)
        .navigationTitle("Podcasts")
        .toolbar { toolbar }
        .task { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension PodcastListView {
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.showNewPodcast()
            } label: {
                Image(systemSymbol: .plusCircle)
            }
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        if viewModel.podcasts.isEmpty {
            ContentUnavailableView(
                "Empty",
                image: "",
                description: Text("Empty")
            )
        }
    }
}
