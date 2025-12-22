//
//  SettingsView.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 21..
//

import SwiftUI

struct SettingsView: View {

    // MARK: Dependencies

    @InjectedObject private var viewModel: SettingsViewModel

    // MARK: UI

    var body: some View {
        List {
            Section("Storage") {
                Text("Donwloads: 203,4")

                Button("Delete") {
                    
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(L10n.settings)
    }
}
