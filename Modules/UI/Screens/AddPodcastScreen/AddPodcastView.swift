//
//  AddPodcastView.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import SwiftUI

import UIComponentKit

internal import SFSafeSymbols

struct AddPodcastView: View {

    // MARK: Dependencies

    @State private var viewModel = AddPodcastViewModel()
    @FocusState private var isFocused

    // MARK: UI

    var body: some View {
        VStack(spacing: 16) {
            image
            title
            textField
            Spacer()
            buttons
        }
        .padding()
        .navigationTitle("Subscribe with URL")
        .navigationBarTitleDisplayMode(.inline)
//        .presentationDetents([.medium])
        .dialog(descriptor: $viewModel.currentlyShowingDialog)
        .onAppear { isFocused = true }
    }
}

// MARK: - Helpers

extension AddPodcastView {
    private var image: some View {
        Image(systemSymbol: .linkCircle)
            .font(.system(size: 52))
            .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)
            .frame(height: 56)
    }

    private var title: some View {
        Text("Subscribe to a private podcast by entering its URL")
            .font(.bodyText)
            .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
    }

    @ViewBuilder
    private var textField: some View {
        TextField("", text: $viewModel.feedURL, axis: .vertical)
            .focused($isFocused)
            .textFieldStyle(.custom(title: "URL", icon: Image(systemSymbol: .link), height: 132))
            .validate($viewModel.feedURL, rule: viewModel.urlValidationRule)
            .validate($viewModel.addPodcastResult)
    }

    private var buttons: some View {
        VStack(spacing: 8) {
            AsyncButton("Subscribe") { await viewModel.addPodcast() }
                .buttonStyle(.primary(fill: true))
                .disabled(!viewModel.urlValidationRule.isValid)

            Button("Cancel") { viewModel.dismiss() }
                .buttonStyle(.secondary(fill: true))
        }
    }
}
