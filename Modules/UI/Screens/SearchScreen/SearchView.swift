//
//  SearchView.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 21..
//

import SwiftUI

import Domain
import UIComponentKit

internal import SFSafeSymbols
internal import NukeUI

struct SearchView: View {

    // MARK: Dependencies

    @State private var viewModel = SearchViewModel()

    // MARK: Private properties

    @FocusState private var isSearchFocused
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { [viewModel] in viewModel.searchKeyword ?? "" },
            set: { [viewModel] in viewModel.changeSearchKeyword(!$0.isEmpty ? $0 : nil) }
        )
    }

    // MARK: UI

    var body: some View {
        List {
            if let podcasts = viewModel.podcasts {
                ForEach(podcasts) { podcast in
                    podcastItem(for: podcast)
                        .id(podcast)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: searchTextBinding)
        .searchFocused($isSearchFocused)
        .searchToolbarBehavior(.minimize)
        .animation(.default, value: viewModel.podcasts)
        .task(id: "SearchView.SubscriptionTask") { await viewModel.subscribe() }
        .onAppear { isSearchFocused = true }
        .overlay {
            if let podcasts = viewModel.podcasts, podcasts.isEmpty {
                ContentUnavailableView(
                    "Search",
                    image: "magnifyingglass",
                    description: Text(#"Not found podcasts with \#(viewModel.searchKeyword)"#)
                )
            }
        }
    }
}

// MARK: - Helpers

extension SearchView {
    private func podcastItem(for podcast: Podcast) -> some View {
        HStack(spacing: 16) {
            LazyImage(url: podcast.imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                }
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading) {
                Text(podcast.title)
                    .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(podcast.author ?? "")
                    .font(.captionText)
                    .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AsyncButton {
                await viewModel.toggleSubscription(for: podcast)
            } label: {
                Image(systemSymbol: podcast.isSubscribed ? .minusCircleFill : .plusCircleFill)
            }
            .foregroundStyle(podcast.isSubscribed ? Asset.Colors.State.error.swiftUIColor : Asset.Colors.accentPrimary.swiftUIColor)
        }
    }
}
