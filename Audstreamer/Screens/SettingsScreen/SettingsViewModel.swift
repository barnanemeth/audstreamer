//
//  SettingsViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import Foundation
import Combine
import UIKit

final class SettingsViewModel: ObservableObject {

    // MARK: Dependencies

    @Injected private var account: Account
    @Injected private var downloadService: DownloadService
    @Injected private var networking: Networking
    @Injected private var socket: Socket
    @Injected private var database: Database
    @Injected private var navigator: Navigator

    // MARK: Properties

//    var navigateToLoginScreenAction: CocoaAction?
//    var presentDeleteDownloadActionSheetAction: CocoaAction?
//    var presentLogoutActionSheetAction: CocoaAction?
//    var presentErrorAlertAction: Action<Error, Never>?
    @Published var isLoading = false
    var sections: AnyPublisher<[SettingsSection], Never> {
        Publishers.CombineLatest3(downloadSize, socketStatus, isLoggedIn)
            .map { [unowned self] in self.buildSections(downloadSize: $0, socketStatus: $1, isLoggedIn: $2) }
            .eraseToAnyPublisher()
    }

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var downloadSize: AnyPublisher<Int, Never> {
        downloadService.getDownloadSize()
            .replaceError(with: .zero)
            .eraseToAnyPublisher()
    }
    private var socketStatus: AnyPublisher<SocketStatus, Never> {
        socket.getStatus()
            .replaceError(with: .disconnected)
            .eraseToAnyPublisher()
    }
    private var isLoggedIn: AnyPublisher<Bool, Never> {
        account.isLoggedIn()
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
}

// MARK: - Actions

extension SettingsViewModel {
    func handleTap(for item: SettingsItem) {
        switch item {
        case .storageAction: showDeleteDownloadActionSheet()
        case let .accountAction(type): handleAccountAction(type: type)
        case let .socketAction(type): handleSocketAction(type: type)
        default: return
        }
    }

    func deleteDownloads() {
        downloadService.deleteDownloads()
            .receive(on: DispatchQueue.main)
            .flatMap { [unowned self] in self.database.resetDownloadEpisodes() }
            .handleEvents(receiveSubscription: { [unowned self] _ in self.isLoading = true },
                          receiveCompletion: { [unowned self] _ in self.isLoading = false })
            .sink(receiveCompletion: { [unowned self] completion in
                guard case let .failure(error) = completion else { return }
                navigator.presentAlert(for: error)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    func logout() {
        networking.deleteDevice()
            .catch { _ in Just(()) }
            .flatMap { [unowned self] in self.socket.disconnect().catch { _ in Just(()) } }
            .flatMap { [unowned self] in self.account.logout().catch { _ in Just(()) } }
            .flatMap { [unowned self] in self.account.refresh() }
            .handleEvents(receiveSubscription: { [unowned self] _ in self.isLoading = true },
                          receiveCompletion: { [unowned self] _ in self.isLoading = false })
            .sink(receiveCompletion: { [unowned self] completion in
                guard case let .failure(error) = completion else { return }
                navigator.presentAlert(for: error)
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    func navigateToLoginScreen() {
        let loginScreen: LoginScreen = Resolver.resolve()
        loginScreen.setNavigationParameter(LoginScreenParam.shouldShowPlayerAtDismiss(false))
        navigator.present(loginScreen)
    }

    func showDeleteDownloadActionSheet() {
        showActionSheet(
            title: L10n.deleteDownloads,
            message: L10n.deleteDownloadsConfirm,
            confirm: L10n.deleteDownloads,
            action: { [unowned self] in deleteDownloads() }
        )
    }

    func showLogoutActionSheet() {
        showActionSheet(
            title: L10n.logout,
            message: L10n.logoutConfirm,
            confirm: L10n.logout,
            action: { [unowned self] in logout() }
        )
    }
}

// MARK: - Helpers

extension SettingsViewModel {
    private func buildSections(downloadSize: Int, socketStatus: SocketStatus, isLoggedIn: Bool) -> [SettingsSection] {
        [
            getStorageSection(downloadSize: downloadSize),
            getSocketSection(socketStatus: socketStatus, isLoggedIn: isLoggedIn),
            getAccountSection(isLoggedIn: isLoggedIn)
        ]
    }

    private func getStorageSection(downloadSize: Int) -> SettingsSection {
        var items = [SettingsItem]()

        items.append(SettingsItem.storageInfo(downloadSize: downloadSize))

        if downloadSize > .zero {
            items.append(SettingsItem.storageAction)
        }

        return SettingsSection(title: L10n.storage, items: items)
    }

    private func getSocketSection(socketStatus: SocketStatus, isLoggedIn: Bool) -> SettingsSection {
        var items = [SettingsItem]()

        items.append(SettingsItem.socketInfo(status: socketStatus))

        if isLoggedIn {
            let status: SettingsItem.SocketActionType
            switch socketStatus {
            case .disconnected: status = .connect
            case .connected, .pending: status = .disconnect
            }

            items.append(SettingsItem.socketAction(type: status))
        }

        return SettingsSection(title: L10n.socket, items: items)
    }

    private func getAccountSection(isLoggedIn: Bool) -> SettingsSection {
        let actionItem = SettingsItem.accountAction(type: isLoggedIn ? .logout : .login)

        return SettingsSection(title: L10n.account, items: [actionItem])
    }

    private func handleSocketAction(type: SettingsItem.SocketActionType) {
        let socketAction: AnyPublisher<Void, Error>

        switch type {
        case .connect: socketAction = socket.connect()
        case .disconnect: socketAction = socket.disconnect()
        }

        socketAction
            .sink(receiveCompletion: { [unowned self] completion in
                guard case let .failure(error) = completion else { return }
                navigator.presentAlert(for: error)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func handleAccountAction(type: SettingsItem.AccountActionType) {
        switch type {
        case .login: navigateToLoginScreen()
        case .logout: showLogoutActionSheet()
        }
    }

    private func showActionSheet(title: String, message: String, confirm: String, action: @escaping (() -> Void)) {
        #if targetEnvironment(macCatalyst)
        let actionSheet = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        #else
        let actionSheet = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .actionSheet
        )
        #endif
        let confirmAction = UIAlertAction(
            title: confirm,
            style: .destructive,
            handler: { _ in action() }
        )
        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)

        actionSheet.addAction(cancelAction)
        actionSheet.addAction(confirmAction)

        actionSheet.preferredAction = confirmAction

        navigator.presentAlertController(actionSheet)
    }
}
