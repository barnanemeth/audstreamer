//
//  SettingsViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import Foundation
import Combine
import UIKit
import SwiftUI

@Observable
final class SettingsViewModel: ViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var account: Account
    @ObservationIgnored @Injected private var downloadService: DownloadService
    @ObservationIgnored @Injected private var networking: Networking
    @ObservationIgnored @Injected private var socket: Socket
    @ObservationIgnored @Injected private var database: Database
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    private(set) var isLoading = false

    private(set) var downloadSizeText: AttributedString?
    private(set) var isDeleteDownloadsVisible = false

    private(set) var socketConnection: (text: String, iconColor: Color)?
    private(set) var socketActionText: String?

    private(set) var accountAction: (text: String, color: Color)?

    var currentlyShowedDialogDescriptor: DialogDescriptor?
}

// MARK: - View model

extension SettingsViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeToDownloadSize() }
            taskGroup.addTask { await self.subscribeToSocketStatus() }
            taskGroup.addTask { await self.subscribeToAccountStatus() }
        }
    }
}

// MARK: - Actions

extension SettingsViewModel {
    @MainActor
    func deleteDownloads() async {
        do {
            try await downloadService.deleteDownloads().value
            try await database.resetDownloadEpisodes().value
        } catch {
            showErrorAlert(for: error)
        }
    }

    @MainActor
    func handleSocketAction() async {
        switch try? await socket.getStatus().value {
        case .connected, .pending: try? await socket.disconnect().value
        case .disconnected: try? await socket.connect().value
        default: return
        }
    }

    @MainActor
    func handleAccountAction() async {
        let isLoggedIn = (try? await account.isLoggedIn().value) ?? false
        if isLoggedIn {
            showLogoutActionSheet()
        } else {
            navigateToLoginScreen()
        }
    }

    func handleDeleteDownloadsAction() {
        currentlyShowedDialogDescriptor = DialogDescriptor(
            title: L10n.deleteDownloads,
            message: L10n.deleteDownloadsConfirm,
            type: .alert,
            actions: [
                DialogAction(title: L10n.cancel, type: .cancel),
                DialogAction(title: L10n.deleteDownloads, type: .destructive) { [unowned self] in deleteDownloads() }
            ]
        )
    }

    func handleClose() {
        navigator.dismiss()
    }
}

// MARK: - Helpers

extension SettingsViewModel {
    @MainActor
    private func subscribeToDownloadSize() async {
        let publisher = downloadService.getDownloadSize().replaceError(with: .zero)
        for await downloadSize in publisher.asAsyncStream() {
            downloadSizeText = getDownloadSizeText(for: downloadSize)
            isDeleteDownloadsVisible = downloadSize > .zero
        }
    }

    @MainActor
    private func subscribeToSocketStatus() async {
        let socketStatus = socket.getStatus().replaceError(with: .disconnected)
        let loginStatus = account.isLoggedIn().replaceError(with: false)
        let publisher = Publishers.CombineLatest(socketStatus, loginStatus)

        for await (socketStatus, isLoggedIn) in publisher.asAsyncStream() {
            let (statusText, statusColor, actionText) = switch socketStatus {
            case .connected: (L10n.connected, Asset.Colors.success.swiftUIColor, L10n.disconnect)
            case .pending: (L10n.pending, Asset.Colors.warning.swiftUIColor, L10n.disconnect)
            case .disconnected: (L10n.disconnected, Asset.Colors.error.swiftUIColor, L10n.connect)
            }

            socketConnection = (statusText, statusColor)
            socketActionText = if isLoggedIn {
                actionText
            } else {
                nil
            }
        }
    }

    @MainActor
    private func subscribeToAccountStatus() async {
        let publisher = account.isLoggedIn().replaceError(with: false)

        for await isLoggedIn in publisher.asAsyncStream() {
            let (text, color) = if isLoggedIn {
                (L10n.logout, Asset.Colors.error.swiftUIColor)
            } else {
                (L10n.logIn, Asset.Colors.label.swiftUIColor)
            }

            accountAction = (text, color)
        }
    }

    private func showLogoutActionSheet() {
        currentlyShowedDialogDescriptor = DialogDescriptor(
            title: L10n.logout,
            message: L10n.logoutConfirm,
            type: .alert,
            actions: [
                DialogAction(title: L10n.cancel, type: .cancel),
                DialogAction(title: L10n.logout, type: .destructive) { [unowned self] in logout() }
            ]
        )
    }

    private func logout() {
        Task { @MainActor in
            defer { isLoading = false }
            do {
                isLoading = true
                try? await networking.deleteDevice().value
                try? await socket.disconnect().value
                try await account.logout().value
                try await account.refresh().value
            } catch {
                showErrorAlert(for: error)
            }
        }
    }

    private func deleteDownloads() {
        Task { @MainActor in
            defer { isLoading = false }
            do {
                isLoading = true
                try await downloadService.deleteDownloads().value
                try await database.resetDownloadEpisodes().value
            } catch {
                showErrorAlert(for: error)
            }
        }
    }

    private func navigateToLoginScreen() {
        let loginScreen: LoginScreen = Resolver.resolve(args: false)
        navigator.present(loginScreen)
    }

    private func getDownloadSizeText(for downloadSize: Int) -> AttributedString? {
        let downloadSizeString = NumberFormatterHelper.getFormattedContentSize(from: downloadSize)
        let text = L10n.downloadsSize(downloadSizeString)

        return try? AttributedString(markdown: text)
    }

    private func showErrorAlert(for error: Error) {
        currentlyShowedDialogDescriptor = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
    }
}
