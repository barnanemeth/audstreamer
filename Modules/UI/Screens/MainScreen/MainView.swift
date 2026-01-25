//
//  MainView.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 14..
//

import SwiftUI

import Common
import UIComponentKit

internal import NavigatorUI
internal import SFSafeSymbols

struct MainView: View {

    // MARK: Dependencies

    @State private var viewModel = MainViewModel()

    // MARK: Private properties

    @Environment(\.navigator) private var navigator
    @State private var selectedTab: MainTab = .dashboard

    // MARK: UI

    var body: some View {
        tabView
            .safeAreaInset(edge: .top) { downloadingWidget }
            .safeAreaInset(edge: .top) { fileTransferWidget }
            .task(id: "MainView.SubscriptionTask") { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension MainView {
    private var tabView: some View {
        TabView(selection: $selectedTab) {
            Tab(L10n.dashboard, systemSymbol: .houseFill, value: .dashboard) { dashboard }
            Tab("Library", systemSymbol: .squareStack, value: .podcasts) { podcastList }
            Tab(L10n.settings, systemSymbol: .gearshapeFill, value: .settings) { settings }
            Tab(value: .search, role: .search) { search }
        }
        .tint(Asset.Colors.primary.swiftUIColor)
        .tabBarMinimizeBehavior(.onScrollDown)
        .apply {
            if #available(iOS 26.1, *) {
                $0.tabViewBottomAccessory(isEnabled: viewModel.isPlayerBottomWidgetVisible) {
                    playerBottomWidget
                }
            } else {
                $0.tabViewBottomAccessory {
                    if viewModel.isPlayerBottomWidgetVisible {
                        playerBottomWidget
                    }
                }
            }
        }
        .onNavigationReceive { (event: MainTab) in
            selectedTab = event
            return .auto
        }
    }

    private var dashboard: some View {
        ManagedNavigationStack {
            navigator.mappedNavigationView(for: AppNavigationDestination.dashboard)
        }
    }

    private var podcastList: some View {
        ManagedNavigationStack {
            navigator.mappedNavigationView(for: AppNavigationDestination.podcastList)
        }
    }

    private var settings: some View {
        ManagedNavigationStack {
            navigator.mappedNavigationView(for: AppNavigationDestination.settings)
        }
    }

    private var search: some View {
        ManagedNavigationStack {
            navigator.mappedNavigationView(for: AppNavigationDestination.search)
        }
    }

    private var playerBottomWidget: some View {
        PlayerBottomWidget {
            viewModel.showPlayerScreen()
        }
    }

    private var downloadingWidget: some View {
        LoadingWidget(viewModel: DownloadingWidgetViewModel()) {
            viewModel.showDownloads()
        }
    }

    private var fileTransferWidget: some View {
        LoadingWidget(viewModel: FileTransferWidgetViewModel())
    }
}
