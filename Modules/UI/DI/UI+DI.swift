//
//  UI+DI.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Common

extension Resolver {
    @MainActor
    public static func registerUI() {
        registerNavigator()
        registerScreens()
    }
}

extension Resolver {
    @MainActor
    private static func registerNavigator() {
        register { DefaultNavigator() }
            .implements(NavigatorPublic.self)
            .implements(Navigator.self)
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
    }

    private static func registerPlayerScreen() {
        register { PlayerViewModel() }
            .scope(.unique)
    }

    private static func registerLoginScreen() {
        register { (_, args: Resolver.Args) in
            LoginViewModel(shouldShowPlayerAtDismiss: args.get())
        }
        .scope(.unique)
    }

    private static func registerSettingsScreen() {
        register { SettingsViewModel() }
            .scope(.unique)
    }

    private static func registerDownloadsScreen() {
        register { DownloadsViewModel() }
            .scope(.unique)
    }

    private static func registerLoadingWidgets() {
        register { DownloadingWidgetViewModel() }
            .scope(.unique)

        register { FileTransferWidgetViewModel() }
            .scope(.unique)
    }
}
