//
//  DevicesScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation
import Combine

final class DevicesScreenViewModel: ScreenViewModel {

    // MARK: Dependencies

    @Injected private var socket: Socket

    // MARK: Properties

    var devices: AnyPublisher<[Device], Never> {
        socket.getDeviceList()
            .removeDuplicates()
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    var activeDevice: AnyPublisher<String?, Never> {
        socket.getActiveDevice()
            .removeDuplicates()
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    // MARK: Private propertie

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Actions

extension DevicesScreenViewModel {
    func setActiveDeviceID(_ activeDeviceID: String) {
        socket.sendActiveDevice(activeDeviceID).sink().store(in: &cancellables)
    }
}
