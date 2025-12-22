//
//  ApplicationLoader.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 03..
//

import UIKit
import Combine
import BackgroundTasks

import Nuke

final class ApplicationLoader: NSObject {

    // MARK: Constants

    private enum Constant {
        static let backgroundTaskIdentifier = "hu.barnanemeth.dev.Audstreamer.backgroundFetch"
        static let databaseSyncBackgroundTaskIdentifier = "hu.barnanemeth.dev.Audstreamer.databaseSyncTask"
    }

    // MARK: Dependencies

    @LazyInjected private var applicationStateHandler: ApplicationStateHandler
    @LazyInjected private var database: Database
    @LazyInjected private var networking: Networking
    @LazyInjected private var notificationHandler: NotificationHandler
    @LazyInjected private var cloud: Cloud
    @LazyInjected private var shortcutHandler: ShortcutHandler
    @LazyInjected private var navigator: Navigator

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var publicCloudSynchronizationCancellable: AnyCancellable?
}

// MARK: - Public methods

extension ApplicationLoader {
    func load(with window: UIWindow?) {
        Resolver.setupDI()
        applicationStateHandler.start()
        setupWindow(window)
        setupBackgroundRefresh()
        notificationHandler.setupNotifications()
        setupImageLoading()
        shortcutHandler.setupItems()
        resetBadge()
    }

    func synchronizePrivateCloud() {
        cloud.synchronizePrivateData().sink().store(in: &cancellables)
    }

    func synchronizePublicCloud() {
        let backgroundTask = BackgroundTask(id: Constant.databaseSyncBackgroundTaskIdentifier)
        let expirationHandler: (() -> Void) = { [unowned self] in self.publicCloudSynchronizationCancellable?.cancel() }
        publicCloudSynchronizationCancellable = cloud.synchronizePublicData()
            .handleEvents(receiveSubscription: { _ in backgroundTask.begin(expirationHandler: expirationHandler) })
            .sink(receiveCompletion: { _ in backgroundTask.end() }, receiveValue: { })
    }
}

// MARK: - Helpers

extension ApplicationLoader {
    private func setupWindow(_ window: UIWindow?) {
        navigator.setup(with: window)

        let loadingScreen: LoadingScreen = Resolver.resolve()
        navigator.start(with: loadingScreen)
    }

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
        database.getLastEpisodePublishDate()
            .first()
            .flatMap { [unowned self] in self.networking.getEpisodes(from: $0) }
            .flatMap { [unowned self] in self.database.insertEpisodes($0) }
            .eraseToAnyPublisher()
    }

    private func setupImageLoading() {
        let contentModes = ImageLoadingOptions.ContentModes(
            success: .scaleAspectFill,
            failure: .scaleAspectFill,
            placeholder: .scaleAspectFill
        )
        ImageLoadingOptions.shared.contentModes = contentModes
        ImageLoadingOptions.shared.placeholder = Asset.Images.logoLarge.image
        ImageLoadingOptions.shared.failureImage = Asset.Images.logoLarge.image
        ImageLoadingOptions.shared.transition = .fadeIn(duration: 0.3)
    }

    private func resetBadge() {
        UIApplication.shared.applicationIconBadgeNumber = .zero
    }
}
