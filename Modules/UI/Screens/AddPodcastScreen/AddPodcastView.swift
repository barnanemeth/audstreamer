//
//  AddPodcastView.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import SwiftUI

import UIComponentKit

struct AddPodcastView: View {

    // MARK: Dependencies

    @State private var viewModel = AddPodcastViewModel()

    // MARK: UI

    var body: some View {
        VStack {
            Text("Add new podcast")
                .font(.headline)
                .foregroundStyle(Asset.Colors.label.swiftUIColor)

            TextEditor(text: $viewModel.feedURL)
                .textEditorStyle(.automatic)

            AsyncButton {
                await viewModel.addPodcast()
            } label: {
                Text("Get podcast")
            }
            .disabled(viewModel.feedURL.isEmpty)
            .buttonStyle(.glass)

        }
        .tint(Asset.Colors.primary.swiftUIColor)
        .padding()
        .presentationDetents([.medium])
    }
}

// MARK: - Helpers

extension AddPodcastView {

}
