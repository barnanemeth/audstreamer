//
//  EpisodeListView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 29..
//

import SwiftUI

import Common
import Domain
import UIComponentKit

internal import SFSafeSymbols

struct EpisodeListView: View {

    // MARK: Dependencies

    @State private var viewModel = EpisodeListViewModel()

    // MARK: Properties

    let podcast: Podcast?

    // MARK: Private properties

    @FocusState private var isSearchEnabled: Bool
    @State private var listScrollViewProxy: ScrollViewProxy?
    private var searchTextBinding: Binding<String> {
        Binding<String>(
            get: { [viewModel] in viewModel.searchKeyword ?? "" },
            set: { [viewModel] in viewModel.setSearchKeyword($0) }
        )
    }

    // MARK: UI

    var body: some View {
        ScrollViewReader { proxy in
            List {
                listContent
            }
            .background(Asset.Colors.surfaceBase.swiftUIColor)
            .scrollContentBackground(.hidden)
            .overlay { emptyView }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .animation(.default, value: viewModel.sections)
            .searchable(text: searchTextBinding, placement: .toolbar)
            .searchFocused($isSearchEnabled)
            .onAppear { listScrollViewProxy = proxy }
        }
        .toolbar { toolbar }
        .navigationTitle(podcast?.title ?? viewModel.screenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "EpisodeListView.SubscriptionTask") { await viewModel.subscribe() }
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
        .feedbackEnabled(true)
        .onAppear { viewModel.setPodcast(podcast) }
        .onChange(of: viewModel.openedEpisodeID) {
            guard let openedEpisodeID = viewModel.openedEpisodeID else { return }
            listScrollViewProxy?.scrollTo(openedEpisodeID, anchor: .top)
            listScrollViewProxy = nil
        }
    }
}

// MARK: - Helpers

extension EpisodeListView {
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(viewModel.filterAttributes, id: \.self) { attribute in
                    let isOn = Binding<Bool>(
                        get: { attribute.isActive },
                        set: { [viewModel] _ in viewModel.toggleFilterAttribute(attribute) }
                    )
                    Toggle(attribute.title, systemImage: attribute.systemImage, isOn: isOn)
                }
            } label: {
                let systemSymbol: SFSymbol = if viewModel.isFilterActive {
                    .line3HorizontalDecreaseCircleFill
                } else {
                    .line3HorizontalDecreaseCircle
                }
                Image(systemSymbol: systemSymbol)
            }
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.navigateToSettings()
            } label: {
                Image(systemSymbol: .gear)
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if let sections = viewModel.sections {
            ForEach(sections) { section in
                EpisodeSectionComponent(
                    section: section,
                    isTitleButtonVisible: !viewModel.isFilterActive,
                    onHeaderTap: { viewModel.openedEpisodeID = section.id },
                    onPlayPauseTap: { await viewModel.togglePlaying(section.episode) },
                    onFavouriteTap: { await viewModel.toggleEpisodeFavorite(section.episode) },
                    onDownloadTap: { await viewModel.downloadDeleteEpisode(section.episode) },
                    onWatchTap: { await viewModel.toggleEpisodeIsOnWatch(section.episode) },
                    onSectionDownloadTap: { await viewModel.downnloadOrDeletedEpisodes(for: section) }
                )
                .listRowBackground(Asset.Colors.surfaceElevated.swiftUIColor)
            }
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        if let sections = viewModel.sections, sections.isEmpty {
            ContentUnavailableView("", systemSymbol: .exclamationmarkCircle, description: Text(L10n.noResults))
                .fontWeight(.semibold)
        }
    }
}
