//
//  WatchAppDelegate.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 19..
//

import WatchKit
import Combine

import Common
import Domain

final class WatchAppDelegate: NSObject {

    // MARK: Dependencies

    @LazyInjected private var episodeService: EpisodeService

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - WKApplicationDelegate
extension WatchAppDelegate: WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        registerServices()
    }

    func applicationDidEnterBackground() {
        refreshEpisodes()
    }

    func applicationDidBecomeActive() {
        refreshEpisodes()
    }
}

// MARK: - Helpers

extension WatchAppDelegate {
    private func registerServices() {
        Resolver.register { WatchEpisodeService() }
            .implements(EpisodeService.self)
            .scope(.cached)

        Resolver.register { WatchAudioPlayer() }
            .implements(AudioPlayer.self)
            .scope(.cached)

        Resolver.register { WatchRemotePlayer() }
            .implements(RemotePlayer.self)
            .scope(.cached)
    }

    private func refreshEpisodes() {
        episodeService.refresh()
            .replaceError(with: ())
            .sink()
            .store(in: &cancellables)
    }
}
