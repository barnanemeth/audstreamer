//
//  App+DI.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import UIKit

import Reachability

// MARK: - Public methods

extension Resolver {
    static func setupDI() {
        registerKeyWindow()
        registerAppServices()
        registerNavigator()
        registerScreens()
    }
}

// MARK: - Private methods

extension Resolver {
    private static func registerAppServices() {
        registerApplicationStateHandler()
        registerNetworking()
        registerDatabase()
        registerCloud()
        registerAuthorization()
        registerSecureStore()
        registerSocket()
        registerAudioPlayer()
        registerRemotePlayer()
        registerPlayingUpdater()
        registerSocketUpdater()
        registerDatabaseUpdater()
        registerNotificationHandler()
        registerAccount()
        registerDownloadService()
        registerReachability()
        registerFilterService()
        registerShortcutHandler()
        registerWatchConnectivityService()
    }

    private static func registerNavigator() {
        register { Navigator() }
            .scope(.cached)
    }

    private static func registerScreens() {
        registerLoadingScreen()
        registerLoginScreen()
        registerPlayerScreen()
        registerDevicesScreen()
        registerSettingsScreen()
        registerDownloadsScreen()
    }
    private static func registerKeyWindow() {
        register { UIApplication.shared.windows.first { $0.isKeyWindow } }
            .scope(.unique)
    }

    private static func registerApplicationStateHandler() {
        register { DefaultApplicationStateHandler() }
            .implements(ApplicationStateHandler.self)
            .scope(.cached)
    }

    private static func registerNetworking() {
        register { DefaultAPIClient() }
            .implements(Networking.self)
            .scope(.cached)
    }

    private static func registerDatabase() {
        register { RealmDatabase() }
            .implements(Database.self)
            .scope(.cached)
    }

    private static func registerCloud() {
        register { CloudKitCloud() }
            .implements(Cloud.self)
            .scope(.cached)
    }

    private static func registerAuthorization() {
        register { AppleIDAuthorization() }
            .implements(Authorization.self)
            .scope(.unique)
    }

    private static func registerSecureStore() {
        register { KeychainSecureStore() }
            .implements(SecureStore.self)
            .scope(.cached)
    }

    private static func registerSocket() {
        register { SocketIOSocket() }
            .implements(Socket.self)
            .scope(.cached)
    }

    private static func registerAudioPlayer() {
        register { DefaultAudioPlayer() }
            .implements(AudioPlayer.self)
            .scope(.cached)
    }

    private static func registerRemotePlayer() {
        register { DefaultRemotePlayer() }
            .implements(RemotePlayer.self)
            .scope(.cached)
    }

    private static func registerPlayingUpdater() {
        register { PlayingUpdater() }
            .scope(.cached)
    }

    private static func registerSocketUpdater() {
        register { SocketUpdater() }
            .scope(.cached)
    }

    private static func registerDatabaseUpdater() {
        register { DatabaseUpdater() }
            .scope(.cached)
    }

    private static func registerNotificationHandler() {
        register { DefaultNotificationHandler() }
            .implements(NotificationHandler.self)
            .scope(.cached)
    }

    private static func registerAccount() {
        register { DefaultAccount() }
            .implements(Account.self)
            .scope(.cached)
    }

    private static func registerDownloadService() {
        register { DefaultDownloadService() }
            .implements(DownloadService.self)
            .scope(.cached)
    }

    private static func registerReachability() {
        register { try? Reachability() }
            .scope(.unique)
    }

    private static func registerFilterService() {
        register { DefaultFilterService() }
            .implements(FilterService.self)
            .scope(.cached)
    }

    private static func registerShortcutHandler() {
        register { DefaultShortcutHandler() }
            .implements(ShortcutHandler.self)
            .scope(.cached)
    }

    private static func registerWatchConnectivityService() {
        register { DefaultWatchConnectivityService() }
            .implements(WatchConnectivityService.self)
            .scope(.cached)
    }

    private static func registerLoadingScreen() {
        register { LoadingScreen() }
            .scope(.unique)
    }

    private static func registerPlayerScreen() {
        register { PlayerScreenViewModel() }
            .scope(.unique)

        register { PlayerScreen() }
            .scope(.unique)
    }

    private static func registerLoginScreen() {
        register(LoginScreen.self) { (_, args: Resolver.Args) in
            LoginScreen(viewModel: LoginScreenViewModel(shouldShowPlayerAtDismiss: args.get()))
        }
        .scope(.unique)
    }

    private static func registerDevicesScreen() {
        register { DevicesScreenViewModel() }
            .scope(.unique)

        register { DevicesScreen() }
            .scope(.unique)
    }

    private static func registerSettingsScreen() {
        register { SettingsScreen() }
            .scope(.unique)
    }

    private static func registerDownloadsScreen() {
        register { DownloadsScreenViewModel() }
            .scope(.unique)

        register { DownloadsScreen() }
            .scope(.unique)
    }
}
