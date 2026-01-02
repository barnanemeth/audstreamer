//
//  DeviceHelper.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 22..
//

import UIKit
import Combine

public enum DeviceHelper {

    // MARK: Properties

    public static var deviceID: String {
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else {
            preconditionFailure("Cannot get identifierForVendor")
        }
        return deviceID
    }
    public static var deviceName: String {
        UIDevice.current.name
    }
    public static var deviceModel: String {
        UIDevice.current.model
    }
}

// MARK: - Public methods

extension DeviceHelper {
    public static func isDeviceIDCurrent(_ deviceID: String?) -> Bool {
        Self.deviceID == deviceID
    }
}
