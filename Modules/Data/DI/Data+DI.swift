//
//  Data+DI.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import SwiftData

import Common
import Domain

internal import Reachability
internal import AudstreamerAPIClient
internal import OpenAPIURLSession

extension Resolver {
    public static func registerDataServices() {
        registerInternalServices()
        registerPublicServices()
    }
}

// MARK: - Public services

extension Resolver {
    private static func registerPublicServices() {
        registerPodcastService()
        registerEpisodeService()
        registerCloud()
        registerSocket()
        registerAudioPlayer()
        registerRemotePlayer()
        registerReachability()
        registerShortcutHandler()
        registerWatchConnectivityService()
        registerNotificationHandler()
        registerAccount()
    }

    private static func registerPodcastService() {
        register { DefaultPodcastService() }
            .implements(PodcastService.self)
            .scope(.unique)
    }

    private static func registerEpisodeService() {
        register { DefaultEpisodeService() }
            .implements(EpisodeService.self)
            .scope(.cached)
    }

    private static func registerCloud() {
        register { CloudKitCloud() }
            .implements(Cloud.self)
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

    private static func registerReachability() {
        register { try? Reachability() }
            .scope(.unique)
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
}

// MARK: - Internal services

extension Resolver {
    private static func registerInternalServices() {
        registerClient()
        registerSwiftDataConextManager()
        registerDatabase()
        registerApplicationStateHandler()
        registerAuthorization()
        registerSecureStore()
        registerPlayingUpdater()
        registerSocketUpdater()
        registerDatabaseUpdater()
        registerDownloadService()
    }

    private static func registerClient() {
        register {
            Client(
                serverURL: AppSettings.apiURL,
                transport: URLSessionTransport(),
                middlewares: [APIClientMiddleware()]
            )
        }
        .scope(.unique)
    }

    private static func registerSwiftDataConextManager() {
        register { SwiftDataContextManager.instantiate() }
        .scope(.cached)
    }

    private static func registerDatabase() {
        register { SwiftDataDatabase() }
            .implements(Database.self)
            .scope(.cached)
    }

    private static func registerApplicationStateHandler() {
        register { DefaultApplicationStateHandler() }
            .implements(ApplicationStateHandler.self)
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
            .scope(.unique)
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

    private static func registerDownloadService() {
        register { DefaultDownloadService() }
            .implements(DownloadService.self)
            .scope(.cached)
    }
}
