//
//  LoadingScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import UIKit

@Observable
final class LoadingViewModel: ViewModel {

    // MARK: Constants

    private enum Constant {
        static let animationPath = Bundle.main.url(forResource: "LoadingAnimation", withExtension: "json")?.path
    }

    // MARK: Dependencies

    @ObservationIgnored @Injected private var account: Account
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    let animationPath = Constant.animationPath ?? ""
    private(set) var isLoading = true
    var currentlyShowedDialogDescriptor: DialogDescriptor?
}

// MARK: - View model

extension LoadingViewModel {
    func subscribe() async { }
}

// MARK: - Actions

extension LoadingViewModel {
    @MainActor
    func fetchData() async {
        defer { isLoading = false }
        do {
            isLoading = true
            try await FetchUtil.fetchData().value
            await navigateNext()
        } catch {
            presentErrorAlert(for: error)
        }
    }
}

// MARK: - Helpers

extension LoadingViewModel {
    @MainActor
    private func navigateNext() async {
        do {
            try await account.refresh().value
            let isLoggedIn = try await account.isLoggedIn().value
            if isLoggedIn {
                navigateToPlayerScreen()
            } else {
                navigateToLoginScreen()
            }
        } catch {
            NSLog("Cancellation error")
        }
    }

    private func navigateToPlayerScreen() {
        let playerScreen: PlayerScreen = Resolver.resolve()
        let navigationController = UINavigationController(rootViewController: playerScreen) // Note: with SwiftUI this is not necessary
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.definesPresentationContext = true
        navigator.present(navigationController)
    }

    private func navigateToLoginScreen() {
        let loginScreen: LoginScreen = Resolver.resolve(args: true)
        navigator.present(loginScreen, interactiveSheetDismissHandler: { [unowned self] in
            navigateToPlayerScreen()
        })
    }

    private func presentErrorAlert(for error: Error) {
        currentlyShowedDialogDescriptor = DialogDescriptor(
            title: L10n.error,
            message: error.localizedDescription,
            type: .alert,
            actions: [
                DialogAction(title: L10n.retry, type: .normal) { [unowned self] in Task { await fetchData() } },
                DialogAction(title: L10n.continue, type: .normal) { [unowned self] in navigateToPlayerScreen() }
            ]
        )
    }
}
