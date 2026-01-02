//
//  PlayerView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 29..
//

import SwiftUI

import Common
import Domain
import UIComponentKit

internal import SFSafeSymbols

struct PlayerView: ScreenView {

    // MARK: Dependencies

    @Bindable var viewModel: PlayerViewModel

    // MARK: Private properties

    @FocusState private var isSearchEnabled: Bool
    @State private var isPlayerWidgetVisible = true
    @State private var listScrollViewProxy: ScrollViewProxy?
    private var searchTextBinding: Binding<String> {
        Binding<String>(
            get: { viewModel.searchKeyword ?? "" },
            set: { viewModel.setSearchKeyword($0) }
        )
    }

    // MARK: UI

    var body: some View {
        ScrollViewReader { proxy in
            List {
                listContent
            }
            .overlay { emptyView }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .animation(.default, value: viewModel.sections)
            .safeAreaInset(edge: .top) { downloadingWidget }
            .safeAreaInset(edge: .top) { fileTransferWidget }
            .refreshable { await viewModel.refresh() }
            .searchable(text: searchTextBinding, placement: .toolbarPrincipal)
            .searchFocused($isSearchEnabled)
            .onAppear { listScrollViewProxy = proxy }
        }
        .toolbar { toolbar }
        .navigationTitle(viewModel.screenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.subscribe() }
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
        .feedbackEnabled(true)
        .sheet(isPresented: $isPlayerWidgetVisible) { playerWidget }
        .onChange(of: isSearchEnabled) { isPlayerWidgetVisible = !isSearchEnabled }
    }
}

// MARK: - Helpers

extension PlayerView {
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        searchToolbarItem
        watchToolbarItem
        filterToolbarItem
        settingsToolbarItem
    }

    private var searchToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                isSearchEnabled.toggle()
            } label: {
                Image(systemSymbol: .magnifyingglass)
            }
        }
    }

    @ToolbarContentBuilder
    private var watchToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            switch viewModel.watchConnectionStatus {
            case .notAvailable:
                EmptyView()
            case .available:
                Image(systemSymbol: .applewatch)
            case .connected:
                Image(systemSymbol: .applewatch)
                    .foregroundStyle(Asset.Colors.primary.swiftUIColor)
            }
        }
    }

    @ToolbarContentBuilder
    private var filterToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(viewModel.filterAttributes, id: \.self) { attribute in
                    let isOn = Binding<Bool>(
                        get: { attribute.isActive },
                        set: { _ in viewModel.toggleFilterAttribute(attribute) }
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
                    onPlayTap: { await viewModel.playEpisode(section.episode) },
                    onFavouriteTap: { await viewModel.toggleEpisodeFavorite(section.episode) },
                    onDownloadTap: { await viewModel.downloadDeleteEpisode(section.episode) },
                    onWatchTap: { await viewModel.toggleEpisodeIsOnWatch(section.episode) },
                    onSectionDownloadTap: { await viewModel.downnloadOrDeletedEpisodes(for: section) }
                )
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

    private var playerWidget: some View {
        PlayerWidget(
            isLoading: viewModel.isLoading,
            onTitleTap: { episodeID in
                withAnimation {
                    listScrollViewProxy?.scrollTo(episodeID, anchor: .top)
                    viewModel.openedEpisodeID = episodeID
                }
            }
        )
    }

    private var downloadingWidget: some View {
        LoadingWidget(viewModel: Resolver.resolve(DownloadingWidgetViewModel.self)) {
            viewModel.navigateToDownloads()
        }
    }

    private var fileTransferWidget: some View {
        LoadingWidget(viewModel: Resolver.resolve(FileTransferWidgetViewModel.self))
    }
}
