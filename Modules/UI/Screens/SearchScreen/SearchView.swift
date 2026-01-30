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
internal import NavigatorUI

struct SearchView: View {

    // MARK: Inner types

    enum Mode: Hashable {
        case automatic
        case trending
        case search
    }

    // MARK: Constants

    private enum Constant {
        static let imageSize: CGFloat = 48
    }

    // MARK: Dependencies

    @State private var viewModel = SearchViewModel()

    // MARK: Properties

    @State var mode: Mode?

    // MARK: Private properties

    @Environment(\.navigator) private var navigator
    @FocusState private var isSearchFocused
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { [viewModel] in viewModel.searchKeyword ?? "" },
            set: { [viewModel] in viewModel.changeSearchKeyword(!$0.isEmpty ? $0 : nil) }
        )
    }
    private var sectionHeader: String {
        viewModel.searchKeyword == nil ? "Trending podcasts" : "Search result"
    }

    // MARK: UI

    var body: some View {
        List {
            listContent
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .onNavigationReceive { (mode: AppNavigationDestination.SearchMode) in
            handleReciveSearchMode(mode)
            return .auto
        }
        .searchable(text: searchTextBinding)
        .searchToolbarBehavior(.minimize)
        .apply { view in
            if mode == .search {
                view
                    .onAppear { isSearchFocused = true }
            } else {
                view
            }
        }
        .searchFocused($isSearchFocused)
        .animation(.default, value: viewModel.podcasts)
        .task(id: "SearchView.SubscriptionTask") { await viewModel.subscribe() }
        .overlay { noResultOverlay }
    }
}

// MARK: - Helpers

extension SearchView {
    @ViewBuilder
    private var listContent: some View {
        if let podcasts = viewModel.podcasts {
            Section {
                ForEach(podcasts) { podcast in
                    podcastItem(for: podcast)
                        .id(podcast)
                }
            } header: {
                Text(sectionHeader)
            }
        }
    }

    private func podcastItem(for podcast: Podcast) -> some View {
        Button {
            viewModel.navigateToPodcastDetails(for: podcast)
        } label: {
            HStack(spacing: 12) {
                image(for: podcast)
                info(for: podcast)
                Spacer()
                disclosureIndicator

            }
        }
    }

    private func image(for podcast: Podcast) -> some View {
        ZStack {
            Color.clear
            LazyImage(url: podcast.imageURL) { state in
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                }
            }
        }
        .frame(width: Constant.imageSize, height: Constant.imageSize)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func info(for podcast: Podcast) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(podcast.title)
                .font(.h4)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)

            Text(podcast.author ?? "")
                .font(.bodySecondaryText)
                .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)

            Spacer()
        }
    }

    private var disclosureIndicator: some View {
        Image(systemSymbol: .chevronRight)
            .font(.captionText)
            .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
    }

    @ViewBuilder
    private var noResultOverlay: some View {
        if let podcasts = viewModel.podcasts, podcasts.isEmpty {
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text("No podcasts found for “\(String(describing: viewModel.searchKeyword ?? ""))”.")
            )
        }
    }

    private func handleReciveSearchMode(_ mode: AppNavigationDestination.SearchMode) {
        self.mode = switch mode {
        case .automatic: .automatic
        case .trending: .trending
        case .search: .search
        }
        if mode == .search {
            isSearchFocused = true
        }
    }
}
