//
//  LoginViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import UIKit
import Combine
import UserNotifications

import Common
import Domain
import UIComponentKit

internal import NavigatorUI

@Observable
final class LoginViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var account: Account
    @ObservationIgnored @Injected private var socket: Socket
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    var currentlyShowedDialogDescriptor: DialogDescriptor?
    
    @ObservationIgnored var shouldShowPlayerAtDismiss = false
}

// MARK: - Actions

extension LoginViewModel {
    @MainActor
    func login() async {
        do {
            try await account.login().value
            finishedOrCancelled()
        } catch let authorizationError as AuthorizationError where authorizationError == .userCanceled {
            return
        } catch {
            showErrorAlert(for: error)
        }
    }

    @MainActor
    func handleCancel() {
        finishedOrCancelled()
    }
}

// MARK: - Helpers

extension LoginViewModel {
    @MainActor
    private func finishedOrCancelled() {
        navigator.dismiss()
        if shouldShowPlayerAtDismiss {
            navigator.navigate(to: .main, method: .cover)
        }
    }

    private func showErrorAlert(for error: Error) {
        currentlyShowedDialogDescriptor = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
    }
}
