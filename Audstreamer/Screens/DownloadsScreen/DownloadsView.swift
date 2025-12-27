//
//  DownloadsView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 23..
//

import SwiftUI

import SFSafeSymbols

struct DownloadsView: ScreenView {

    // MARK: Dependencies

    @State var viewModel: DownloadsViewModel

    // MARK: UI

    var body: some View {
        List {
            listContent
        }
        .overlay { completedView }
        .listStyle(.plain)
        .animation(.default, value: viewModel.items)
        .animation(.default, value: viewModel.isCompleted)
        .toolbar { toolbar }
        .navigationTitle(L10n.downloads)
        .task { await viewModel.subscribe() }
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
    }
}

// MARK: - Helpers

extension DownloadsView {
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                viewModel.handleClose()
            } label: {
                Image(systemSymbol: .xmark)
            }
        }
    }

    private var listContent: some View {
        ForEach(viewModel.items, id: \.self) { data in
            DownloadingComponent(data: data)
                .swipeActions { swipeActions(for: data) }
                .id(data)
        }
    }

    @ViewBuilder
    private func swipeActions(for data: DownloadingComponent.Data) -> some View {
        AsyncButton {
            if data.isPaused {
                await viewModel.resume(data.item)
            } else {
                await viewModel.pause(data.item)
            }
        } label: {
            Image(systemSymbol: data.isPaused ? .playFill : .pauseFill)
        }
        .tint(data.isPaused ? Asset.Colors.success.swiftUIColor : Asset.Colors.warning.swiftUIColor)

        AsyncButton {
            await viewModel.cancel(data.item)
        } label: {
            Image(systemSymbol: .stopFill)
        }
        .tint(Asset.Colors.error.swiftUIColor)
    }

    @ViewBuilder
    private var completedView: some View {
        if viewModel.isCompleted {
            ContentUnavailableView("", systemSymbol: .checkmarkCircle, description: Text(L10n.allDownloadsCompleted))
                .foregroundStyle(Asset.Colors.success.swiftUIColor)
                .fontWeight(.semibold)
        }
    }
}
