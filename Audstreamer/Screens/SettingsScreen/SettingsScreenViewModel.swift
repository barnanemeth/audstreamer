//
//  SettingsScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import Foundation
import Combine

final class SettingsScreenViewModel: ScreenViewModel {

    // MARK: Dependencies

    @Injected private var account: Account
    @Injected private var downloadService: DownloadService
    @Injected private var networking: Networking
    @Injected private var socket: Socket
    @Injected private var database: Database

    // MARK: Properties

    var navigateToLoginScreenAction: CocoaAction?
    var presentDeleteDownloadActionSheetAction: CocoaAction?
    var presentLogoutActionSheetAction: CocoaAction?
    var presentErrorAlertAction: Action<Error, Never>?
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

extension SettingsScreenViewModel {
    func handleTap(for item: SettingsItem) {
        switch item {
        case .storageAction: presentDeleteDownloadActionSheetAction?.execute()
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
                self.presentErrorAlertAction?.execute(error)
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
            .sink(receiveCompletion: { completion in
                guard case let .failure(error) = completion else { return }
                self.presentErrorAlertAction?.execute(error)
            }, receiveValue: { })
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension SettingsScreenViewModel {
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
                self.presentErrorAlertAction?.execute(error)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func handleAccountAction(type: SettingsItem.AccountActionType) {
        switch type {
        case .login: navigateToLoginScreenAction?.execute()
        case .logout: presentLogoutActionSheetAction?.execute()
        }
    }
}
