//
//  LoginViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import UIKit
import Combine
import UserNotifications

@Observable
final class LoginViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var authorization: Authorization
    @ObservationIgnored @Injected private var secureStore: SecureStore
    @ObservationIgnored @Injected private var networking: Networking
    @ObservationIgnored @Injected private var account: Account
    @ObservationIgnored @Injected private var socket: Socket
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    var currentlyShowedDialogDescriptor: DialogDescriptor?

    // MARK: Private properties

    @ObservationIgnored private let shouldShowPlayerAtDismiss: Bool

    // MARK: Init

    init(shouldShowPlayerAtDismiss: Bool = false) {
        self.shouldShowPlayerAtDismiss = shouldShowPlayerAtDismiss
    }
}

// MARK: - Actions

extension LoginViewModel {
    @MainActor
    func authorize() async {
        do {
            let authorizationData = try await authorization.authorize().value
            try secureStore.storeToken(authorizationData)
            try await account.refresh().value
            await connectSocketIfNeeded()
            try await requestNotificationPermission()
            try await registerDevice()

            finishedOrCancelled()
        } catch {
            try? secureStore.deleteToken()
            showErrorAlert(for: error)
        }
    }

    func finishedOrCancelled() {
        if shouldShowPlayerAtDismiss {
            let playerScreen: PlayerScreen = Resolver.resolve()
            let navigationController = UINavigationController(rootViewController: playerScreen) // Note: with SwiftUI this is not necessary
            navigationController.modalPresentationStyle = .overCurrentContext
            navigationController.definesPresentationContext = true

            navigator.dismissAndPresent(navigationController)
        } else {
            navigator.dismiss()
        }
    }
}

// MARK: - Helpers

extension LoginViewModel {
    private func requestNotificationPermission() async throws {
        let userNotificationCenter = UNUserNotificationCenter.current()
        try await userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }

    @MainActor
    private func registerDevice() async throws {
        UIApplication.shared.registerForRemoteNotifications()
        guard let notificationToken = UserDefaults.standard.string(forKey: "NotificationToken") else { return }
        try await networking.addDevice(with: notificationToken).value
    }

    private func connectSocketIfNeeded() async {
        do {
            let socketStatus = try await socket.getStatus().value
            if socketStatus != .connected {
                try? await socket.connect().value
            }
        } catch {
            NSLog("Cancellation error")
        }
    }

    private func showErrorAlert(for error: Error) {
        currentlyShowedDialogDescriptor = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
    }
}
