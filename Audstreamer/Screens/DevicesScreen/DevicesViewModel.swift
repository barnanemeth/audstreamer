//
//  DevicesViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation
import Combine

@Observable
final class DevicesViewModel: ViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var socket: Socket

    // MARK: Properties

    private(set) var devices = [Device]()
    private(set) var activeDeviceID: String?
}

// MARK: - View model

extension DevicesViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeToDeviceList() }
            taskGroup.addTask { await self.subscribeToActiveDevice() }
        }
    }
}

// MARK: - Actions

extension DevicesViewModel {
    func setActiveDeviceID(_ activeDeviceID: String) async {
        try? await socket.sendActiveDevice(activeDeviceID).value
    }
}

// MARK: - Helpers

extension DevicesViewModel {
    @MainActor
    private func subscribeToDeviceList() async {
        let publisher = socket.getDeviceList().removeDuplicates().replaceError(with: [])

        for await devices in publisher.values {
            self.devices = devices.sorted(by: { $0.connectionTime < $1.connectionTime })
        }
    }

    @MainActor
    private func subscribeToActiveDevice() async {
        let publisher = socket.getActiveDevice().removeDuplicates().replaceError(with: nil)

        for await activeDeviceID in publisher.values {
            self.activeDeviceID = activeDeviceID
        }
    }
}
