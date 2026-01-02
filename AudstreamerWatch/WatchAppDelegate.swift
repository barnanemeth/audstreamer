//
//  WatchAppDelegate.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 19..
//

//import WatchKit
//import Combine
//
//final class WatchAppDelegate: NSObject {
//
//    // MARK: Dependencies
//
//    @LazyInjected private var episodeService: EpisodeService
//    @LazyInjected private var updater: Updater
//
//    // MARK: Private properties
//
//    private var cancellables = Set<AnyCancellable>()
//}
//
//// MARK: - WKApplicationDelegate
//extension WatchAppDelegate: WKApplicationDelegate {
//    func applicationDidFinishLaunching() {
//        registerServices()
//        startUpdating()
//    }
//
//    func applicationDidEnterBackground() {
//        deleteAbandonedEpisodes()
//    }
//
//    func applicationDidBecomeActive() {
//        sendUpdateTrigger()
//        deleteAbandonedEpisodes()
//    }
//}
//
//// MARK: - Helpers
//
//extension WatchAppDelegate {
//    private func registerServices() {
//        Resolver.register { WatchEpisodeService() }
//            .implements(EpisodeService.self)
//            .implements(DownloadService.self)
//            .scope(.cached)
//
//        Resolver.register { DefaultAudioPlayer() }
//            .implements(AudioPlayer.self)
//            .scope(.cached)
//
//        Resolver.register { WatchRemotePlayer() }
//            .implements(RemotePlayer.self)
//            .scope(.cached)
//
//        Resolver.register { Updater() }
//            .scope(.cached)
//    }
//
//    private func startUpdating() {
//        updater.startUpdating()
//    }
//
//    private func deleteAbandonedEpisodes() {
//        episodeService.deleteAbandonedEpisodes()
//            .replaceError(with: ())
//            .sink()
//            .store(in: &cancellables)
//    }
//
//    private func sendUpdateTrigger() {
//        episodeService.sendUpdateTrigger()
//            .sink()
//            .store(in: &cancellables)
//    }
//}
