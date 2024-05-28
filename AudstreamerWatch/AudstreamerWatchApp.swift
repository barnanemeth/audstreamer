//
//  AudstreamerWatchApp.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import SwiftUI

@main
struct AudstreamerWatchApp: App {

    // MARK: Init

    init() {
        registerServices()
    }

    // MARK: UI

    var body: some Scene {
        WindowGroup {
            EpisodesView()
        }
    }
}

// MARK: - Helpers

extension AudstreamerWatchApp {
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
}
