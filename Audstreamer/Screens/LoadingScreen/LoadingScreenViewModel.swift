//
//  LoadingScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation
import Combine
import UIKit

final class LoadingScreenViewModel: ScreenViewModel {

    // MARK: Constants

    private enum Constant {
        static let navigationDelay: DispatchQueue.SchedulerTimeType.Stride = 1
    }

    // MARK: Dependencies

    @Injected private var account: Account
    @Injected private var navigator: Navigator

    // MARK: Properties

    @Published private(set) var isLoading = false

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Actions

extension LoadingScreenViewModel {
    func fetchData() {
        FetchUtil.fetchData()
            .delay(for: Constant.navigationDelay, scheduler: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [unowned self] _ in self.isLoading = true },
                          receiveCompletion: { [unowned self] _ in self.isLoading = false })
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished: self.navigateNext()
                case let .failure(error): self.presentErrorAlert(for: error)
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension LoadingScreenViewModel {
    private func navigateNext() {
        account.refresh()
            .flatMap { [unowned self] in self.account.isLoggedIn().first() }
            .sink { [unowned self] isLoggedIn in
                if isLoggedIn {
                    navigateToPlayerScreen()
                } else {
                    navigateToLoginScreen()
                }
            }
            .store(in: &cancellables)
    }

    private func navigateToPlayerScreen() {
        let playerScreen: PlayerScreen = Resolver.resolve()
        let navigationController = UINavigationController(rootViewController: playerScreen) // Note: with SwiftUI this is not necessary
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.definesPresentationContext = true
        navigator.present(navigationController)
    }

    private func navigateToLoginScreen() {
        let loginScreen: LoginScreen = Resolver.resolve()
        loginScreen.setNavigationParameter(LoginScreenParam.shouldShowPlayerAtDismiss(true))
        navigator.present(loginScreen, interactiveSheetDismissHandler: { [unowned self] in
            navigateToPlayerScreen()
        })
    }

    private func presentErrorAlert(for error: Error) {
        let alertController = UIAlertController(
            title: L10n.error,
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        let retryAction = UIAlertAction(
            title: L10n.retry,
            style: .default,
            handler: { [unowned self] _ in self.fetchData() }
        )
        let continueAction = UIAlertAction(
            title: L10n.continue,
            style: .default,
            handler: { [unowned self] _ in self.navigateToPlayerScreen() }
        )

        alertController.addAction(retryAction)
        alertController.addAction(continueAction)

        alertController.preferredAction = continueAction

        navigator.presentAlertController(alertController)
    }
}
