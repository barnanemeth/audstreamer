//
//  DevicesView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 25..
//

import SwiftUI

import SFSafeSymbols

struct DevicesView: ScreenView {

    // MARK: Dependencies

    @Bindable var viewModel: DevicesViewModel

    // MARK: UI

    var body: some View {
        List {
            ForEach(viewModel.devices, id: \.id) { device in
                deviceRow(for: device)
                    .id(device)
            }
        }
        .listStyle(.plain)
        .task { await viewModel.subscribe() }
    }
}

// MARK: - Helpers

extension DevicesView {
    func deviceRow(for device: Device) -> some View {
        AsyncButton {
            await viewModel.setActiveDeviceID(device.id)
        } label: {
            HStack {
                let symbol: SFSymbol = switch device.type {
                case .iPhone: .iphone
                case .iPad: .ipad
                default: .questionmarkCircle
                }
                Image(systemSymbol: symbol)
                    .foregroundStyle(Asset.Colors.primary.swiftUIColor)

                Text(device.name)
                    .foregroundStyle(Asset.Colors.label.swiftUIColor)

                Spacer()

                if device.id == viewModel.activeDeviceID {
                    Image(systemSymbol: .checkmark)
                        .foregroundStyle(Asset.Colors.primary.swiftUIColor)
                }
            }
        }
        .disabled(device.id == viewModel.activeDeviceID)
    }
}
