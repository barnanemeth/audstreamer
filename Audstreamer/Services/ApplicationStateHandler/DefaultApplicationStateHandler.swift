//
//  DefaultApplicationStateHandler.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 03..
//

import UIKit
import Combine

final class DefaultApplicationStateHandler {

    // MARK: Private properties

    private lazy var applicationStateSubject = CurrentValueSubject<UIApplication.State, Error>(
        UIApplication.shared.applicationState
    )
    private let notificationCenter = NotificationCenter.default
    private var application: UIApplication { UIApplication.shared }
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - ApplicationStateHandler

extension DefaultApplicationStateHandler: ApplicationStateHandler {
    func start() {
        guard cancellables.isEmpty else { return }
        setupObservers()
    }

    func stop() {
        cancellables.removeAll()
    }

    func getState() -> AnyPublisher<UIApplication.State, Error> {
        applicationStateSubject.removeDuplicates().eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultApplicationStateHandler {
    private func setupObservers() {
        let didBecomeActive = notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
        let didEnterBackground = notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
        let willEnterForeground = notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
        let willResignActive = notificationCenter.publisher(for: UIApplication.willResignActiveNotification)
        let willTerminate = notificationCenter.publisher(for: UIApplication.willTerminateNotification)

        Publishers.MergeMany(didBecomeActive, didEnterBackground, willEnterForeground, willResignActive, willTerminate)
            .toVoid()
            .sink { [unowned self] in self.applicationStateSubject.send(application.applicationState) }
            .store(in: &cancellables)
    }
}
