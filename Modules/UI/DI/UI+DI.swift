//
//  UI+DI.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Common

extension Resolver {
    public static func registerUI() {
        registerNavigator()
        registerScreens()
    }
}

extension Resolver {
    private static func registerNavigator() {
        register { Navigator() }
            .implements(NavigatorPublic.self)
            .scope(.cached)
    }

    private static func registerScreens() {
        registerLoadingScreen()
        registerLoginScreen()
        registerPlayerScreen()
        registerSettingsScreen()
        registerDownloadsScreen()
        registerLoadingWidgets()
    }

    private static func registerLoadingScreen() {
        register { LoadingViewModel() }
            .scope(.unique)

        register { resolver in
            LoadingScreen(viewModel: resolver.resolve())
        }
        .scope(.unique)
    }

    private static func registerPlayerScreen() {
        register { PlayerViewModel() }
            .scope(.unique)

        register { resolver in
            PlayerScreen(viewModel: resolver.resolve())
        }
        .scope(.unique)
    }

    private static func registerLoginScreen() {
        register { (_, args: Resolver.Args) in
            LoginViewModel(shouldShowPlayerAtDismiss: args.get())
        }
        .scope(.unique)

        register { (resolver, args: Resolver.Args) in
            LoginScreen(viewModel: resolver.resolve(args: args.get()))
        }
        .scope(.unique)
    }

    private static func registerSettingsScreen() {
        register { SettingsViewModel() }
            .scope(.unique)

        register { resolver in
            SettingsScreen(viewModel: resolver.resolve())
        }
        .scope(.unique)
    }

    private static func registerDownloadsScreen() {
        register { DownloadsViewModel() }
            .scope(.unique)

        register { resolver in
            DownloadsScreen(viewModel: resolver.resolve())
        }
        .scope(.unique)
    }

    private static func registerLoadingWidgets() {
        register { DownloadingWidgetViewModel() }
            .scope(.unique)

        register { FileTransferWidgetViewModel() }
            .scope(.unique)
    }
}
