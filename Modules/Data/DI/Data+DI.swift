//
//  Data+DI.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import UIKit

import Common
import Domain

internal import Reachability

extension Resolver {
    public static func registerDataServices() {
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
}

extension Resolver {
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
        register { DefaultPlayingUpdater() }
            .implements(PlayingUpdater.self)
            .scope(.cached)
    }

    private static func registerSocketUpdater() {
        register { DefaultSocketUpdater() }
            .implements(SocketUpdater.self)
            .scope(.cached)
    }

    private static func registerDatabaseUpdater() {
        register { DefaultDatabaseUpdater() }
            .implements(DatabaseUpdater.self)
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
}
