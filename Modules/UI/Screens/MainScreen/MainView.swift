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
        TabView {
            Tab("Episodes", systemSymbol: .playCircleFill) {
                ManagedNavigationStack {
                    EpisodeListView()
                }
            }

            Tab("Dashboard", systemSymbol: .appDashed) {
                ManagedNavigationStack {
                    Text("Dashboard")
                }
            }

            Tab(L10n.settings, systemSymbol: .gear) {
                ManagedNavigationStack {
                    SettingsView()
                }
            }

            Tab(role: .search) {
                Text("Search")
            }
        }
        .tint(Asset.Colors.primary.swiftUIColor)
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
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabBarMinimizeBehavior(.onScrollUp)
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
