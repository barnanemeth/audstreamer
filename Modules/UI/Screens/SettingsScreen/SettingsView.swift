//
//  SettingsView.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 21..
//

import SwiftUI

import Common
import UIComponentKit

internal import SFSafeSymbols

struct SettingsView: View {

    // MARK: Dependencies

    @State var viewModel = SettingsViewModel()

    // MARK: UI

    var body: some View {
        List {
            storageSection
            watchConnectionSection
            socketSection
            accountSection
            footerSection
        }
        .listStyle(.grouped)
        .navigationTitle(L10n.settings)
        .toolbar { toolbar }
        .disabled(viewModel.isLoading)
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
        .task(id: "SettingsView.SubscriptionTask") { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension SettingsView {
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if viewModel.isLoading {
            ToolbarItem(placement: .topBarTrailing) {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }

    private var storageSection: some View {
        Section(L10n.storage) {
            Text(viewModel.downloadSizeText ?? AttributedString())

            Button {
                viewModel.navigateToDownloadsScreen()
            } label: {
                Text(L10n.pedingingDownloads)
            }
            .disabled(!viewModel.hasPendingDownloads)

            if viewModel.isDeleteDownloadsVisible {
                Button(L10n.deleteDownloads) {
                    viewModel.handleDeleteDownloadsAction()
                }
                .foregroundStyle(Asset.Colors.State.error.swiftUIColor)
            }
        }
        .font(.bodyText)
        .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
    }

    private var socketSection: some View {
        Section(L10n.socket) {
            if let (text, color) = viewModel.socketConnection {
                statusRow(text: text, color: color)
            }

            if let actionText = viewModel.socketActionText {
                AsyncButton(actionText) {
                    await viewModel.handleSocketAction()
                }
            }
        }
        .font(.bodyText)
        .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
    }

    private var watchConnectionSection: some View {
        Section(L10n.watchConnection) {
            if let (text, color) = viewModel.watchConnection {
                statusRow(text: text, color: color)
            }

            if let transferText = viewModel.pendingWatchTransfersText {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)

                    Text(transferText)
                }
            }
        }
        .font(.bodyText)
        .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
    }

    private var accountSection: some View {
        Section(L10n.account) {
            if let (text, color) = viewModel.accountAction {
                AsyncButton(text) {
                    await viewModel.handleAccountAction()
                }
                .foregroundStyle(color)
            }
        }
        .font(.bodyText)
        .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
    }

    private var footerSection: some View {
        Section {
            EmptyView()
        } footer: {
            SettingsFooterComponent()
                .frame(maxWidth: .infinity)
        }
    }

    private func statusRow(text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(text)
        }
    }
}
