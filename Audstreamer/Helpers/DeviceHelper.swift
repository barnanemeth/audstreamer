//
//  DeviceHelper.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 22..
//

import UIKit
import Combine

enum DeviceHelper {

    // MARK: Properties

    static var deviceID: String {
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else {
            preconditionFailure("Cannot get identifierForVendor")
        }
        return deviceID
    }
    static var deviceName: String {
        UIDevice.current.name
    }
    static var deviceModel: String {
        UIDevice.current.model
    }
    static var isThisDeviceCurrent: AnyPublisher<Bool, Error> {
        @Injected var socket: Socket

        return Publishers.CombineLatest(socket.getActiveDevice(), socket.getDeviceList())
            .map { Self.isDeviceIDCurrent($0) || $1.allSatisfy { $0.id == Self.deviceID } }
            .eraseToAnyPublisher()
    }
}

// MARK: - Public methods

extension DeviceHelper {
    static func isDeviceIDCurrent(_ deviceID: String?) -> Bool {
        Self.deviceID == deviceID
    }
}
