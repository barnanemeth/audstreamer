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
    case player
    case settings
    case downloads

    public static var root: Self { .loading }

    public var body: some View {
        switch self {
        case .loading:
            LoadingView(viewModel: Resolver.resolve())
        case let .login(shouldShowPlayerAtDismiss):
            LoginView(viewModel: Resolver.resolve(args: shouldShowPlayerAtDismiss))
        case .player:
            PlayerView(viewModel: Resolver.resolve())
        case .settings:
            SettingsView(viewModel: Resolver.resolve())
        case .downloads:
            DownloadsView(viewModel: Resolver.resolve())
        }
    }
}

