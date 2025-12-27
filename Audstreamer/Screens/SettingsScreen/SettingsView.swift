//
//  SettingsView.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 21..
//

import SwiftUI

import SFSafeSymbols

struct SettingsView: ScreenView {

    // MARK: Dependencies

    @State var viewModel: SettingsViewModel

    // MARK: UI

    var body: some View {
        List {
            storageSection
            socketSection
            accountSection
            footerSection
        }
        .listStyle(.grouped)
        .navigationTitle(L10n.settings)
        .toolbar { toolbar }
        .disabled(viewModel.isLoading)
        .task { await viewModel.subscribe() }
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
    }
}

// MARK: - Helpers

extension SettingsView {
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                viewModel.handleClose()
            } label: {
                Image(systemSymbol: .xmark)
            }
        }

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

            if viewModel.isDeleteDownloadsVisible {
                Button(L10n.deleteDownloads) {
                    viewModel.handleDeleteDownloadsAction()
                }
                .foregroundStyle(Asset.Colors.error.swiftUIColor)
            }
        }
        .font(.callout)
        .foregroundStyle(Asset.Colors.label.swiftUIColor)
    }

    private var socketSection: some View {
        Section(L10n.socket) {
            if let (text, color) = viewModel.socketConnection {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)

                    Text(text)
                }
            }

            if let actionText = viewModel.socketActionText {
                AsyncButton(actionText) {
                    await viewModel.handleSocketAction()
                }
            }
        }
        .font(.callout)
        .foregroundStyle(Asset.Colors.label.swiftUIColor)
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
        .font(.callout)
        .foregroundStyle(Asset.Colors.label.swiftUIColor)
    }

    private var footerSection: some View {
        Section {
            EmptyView()
        } footer: {
            SettingsFooterComponent()
                .frame(maxWidth: .infinity)
        }
    }
}
