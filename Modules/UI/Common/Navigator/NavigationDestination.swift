//
//  NavigationDestination.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import SwiftUI

import Common

internal import NavigatorUI

enum AppNavigationDestination: @MainActor NavigationDestination {
    case loading
    case login(shouldShowPlayerAtDismiss: Bool)
    case main
    case player(detents: Set<PresentationDetent>)
    case episodeList
    case settings
    case downloads

    public static var root: Self { .loading }

    public var body: some View {
        switch self {
        case .loading:
            LoadingView()
        case let .login(shouldShowPlayerAtDismiss):
            LoginView(shouldShowPlayerAtDismiss: shouldShowPlayerAtDismiss)
        case .main:
            MainView()
        case let .player(detents):
            PlayerView()
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
        case .episodeList:
            EpisodeListView()
        case .settings:
            SettingsView()
        case .downloads:
            DownloadsView()
        }
    }
}
