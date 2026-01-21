//
//  ApplicationLoader.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 03..
//

import UIKit
import Combine
import BackgroundTasks

import Common
import Domain
import UI
import UIComponentKit

import NukeExtensions

final class ApplicationLoader: NSObject {

    // MARK: Constants

    private enum Constant {
        static let backgroundTaskIdentifier = "hu.barnanemeth.dev.Audstreamer.backgroundFetch"
        static let databaseSyncBackgroundTaskIdentifier = "hu.barnanemeth.dev.Audstreamer.databaseSyncTask"
    }

    // MARK: Dependencies

    @LazyInjected private var episodeService: EpisodeService
    @LazyInjected private var notificationHandler: NotificationHandler
    @LazyInjected private var cloud: Cloud
    @LazyInjected private var shortcutHandler: ShortcutHandler
    @LazyInjected private var watchConnectivityService: WatchConnectivityService

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var publicCloudSynchronizationCancellable: AnyCancellable?
}

// MARK: - Public methods

extension ApplicationLoader {
    @MainActor
    func load() {
        Resolver.registerDependencies()
        setupBackgroundRefresh()
        notificationHandler.setupNotifications()
        setupImageLoading()
        shortcutHandler.setupItems()
        resetBadge()
        watchConnectivityService.startUpdating()
    }

    func synchronizePrivateCloud() {
        cloud.synchronizePrivateData().sink().store(in: &cancellables)
    }
}

// MARK: - Helpers

extension ApplicationLoader {
    private func setupBackgroundRefresh() {
        let identifier = Constant.backgroundTaskIdentifier
        let refreshTaskRequest = BGAppRefreshTaskRequest(identifier: identifier)
        refreshTaskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60)

        let launchHandler: ((BGTask) -> Void) = { [unowned self] task in
            task.expirationHandler = { task.setTaskCompleted(success: false) }
            self.fetchAndSaveEpisodes()
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished: task.setTaskCompleted(success: true)
                    case .failure: task.setTaskCompleted(success: false)
                    }
                }, receiveValue: { })
                .store(in: &self.cancellables)
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main, launchHandler: launchHandler)

        try? BGTaskScheduler.shared.submit(refreshTaskRequest)
    }

    private func fetchAndSaveEpisodes() -> AnyPublisher<Void, Error> {
        episodeService.refresh()
    }

    private func setupImageLoading() {
        Task { @MainActor in
            let contentModes = ImageLoadingOptions.ContentModes(
                success: .scaleAspectFill,
                failure: .scaleAspectFill,
                placeholder: .scaleAspectFill
            )
            ImageLoadingOptions.shared.contentModes = contentModes
            ImageLoadingOptions.shared.placeholder = Asset.Images.logoLarge.image
            ImageLoadingOptions.shared.failureImage = Asset.Images.logoLarge.image
            ImageLoadingOptions.shared.transition = .fadeIn(duration: 0.3)

            var options = ImageLoadingOptions()

            options.contentModes = .init(
                success: .scaleAspectFill,
                failure: .scaleAspectFill,
                placeholder: .scaleAspectFill
            )

            options.placeholder = Asset.Images.logoLarge.image
            options.failureImage = Asset.Images.logoLarge.image
            options.transition = .fadeIn(duration: 0.3)
        }
    }

    private func resetBadge() {
        UIApplication.shared.applicationIconBadgeNumber = .zero
    }
}
