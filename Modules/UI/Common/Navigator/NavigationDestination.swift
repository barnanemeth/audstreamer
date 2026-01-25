//
//  NavigationDestination.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import SwiftUI

import Common
import Domain

internal import NavigatorUI

enum AppNavigationDestination: @MainActor NavigationDestination {
    case loading
    case login(shouldShowPlayerAtDismiss: Bool)
    case main
    case player(detents: Set<PresentationDetent>)
    case dashboard
    case podcastList
    case podcastDetails(podcast: Podcast, namespace: Namespace.ID?)
    case addPodcast
    case episodeList(podcast: Podcast?)
    case search
    case settings
    case downloads

    public static var root: Self { .loading }

    public var body: some View {
        switch self {
        case .loading:
            LoadingView()
                .tint(nil)
        case let .login(shouldShowPlayerAtDismiss):
            LoginView(shouldShowPlayerAtDismiss: shouldShowPlayerAtDismiss)
                .tint(nil)
        case .main:
            MainView()
        case let .player(detents):
            PlayerView()
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
                .tint(nil)
        case .dashboard:
            DashboardView()
                .tint(nil)
        case .podcastList:
            PodcastListView()
                .tint(nil)
        case let .podcastDetails(podcast, namespace):
            PodcastDetailsView(podcast: podcast, transitionNamesapce: namespace)
                .tint(nil)
        case .addPodcast:
            AddPodcastView()
                .tint(nil)
        case let .episodeList(podcast):
            EpisodeListView(podcast: podcast)
                .tint(nil)
        case .search:
            SearchView()
                .tint(nil)
        case .settings:
            SettingsView()
                .tint(nil)
        case .downloads:
            DownloadsView()
                .tint(nil)
        }
    }
}
