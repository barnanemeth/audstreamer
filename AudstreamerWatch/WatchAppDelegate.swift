//
//  WatchAppDelegate.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 19..
//

import WatchKit

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        registerServices()
        startUpdating()
    }
}

// MARK: - Helpers

extension WatchAppDelegate {
    private func registerServices() {
        Resolver.register { WatchEpisodeService() }
            .implements(EpisodeService.self)
            .implements(DownloadService.self)
            .scope(.cached)

        Resolver.register { DefaultAudioPlayer() }
            .implements(AudioPlayer.self)
            .scope(.cached)

        Resolver.register { WatchRemotePlayer() }
            .implements(RemotePlayer.self)
            .scope(.cached)

        Resolver.register { Updater() }
            .scope(.cached)
    }

    private func startUpdating() {
        @Injected var updater: Updater
        updater.startUpdating()
    }
}
