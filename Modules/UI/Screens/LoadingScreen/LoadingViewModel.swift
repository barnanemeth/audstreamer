//
//  LoadingScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import UIKit

import Common
import Domain
import UIComponentKit

@Observable
final class LoadingViewModel: ViewModel {

    // MARK: Constants

    private enum Constant {
        static let animationPath = Bundle.main.url(forResource: "LoadingAnimation", withExtension: "json")?.path
    }

    // MARK: Dependencies

    @ObservationIgnored @Injected private var episodeService: EpisodeService
    @ObservationIgnored @Injected private var podcastService: PodcastService
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
            // Note: temporary
//            Task {
//                try await podcastService.refresh().value
//                try await episodeService.refresh().value
//            }
            try await podcastService.refresh().value
            try await episodeService.refresh().value
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
            presentErrorAlert(for: error)
        }
    }

    @MainActor
    private func navigateToPlayerScreen() {
        navigator.navigate(to: .main, method: .cover)
    }

    @MainActor
    private func navigateToLoginScreen() {
        navigator.navigate(to: .login(shouldShowPlayerAtDismiss: true), method: .sheet)
    }

    @MainActor
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
