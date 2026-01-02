//
//  DeviceHelper.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 22..
//

#if os(watchOS)
import WatchKit
#else
import UIKit
#endif
import Combine

public enum DeviceHelper {

    // MARK: Properties

    public static var deviceID: String {
        #if os(watchOS)
        // watchOS does not expose identifierForVendor. Persist a generated UUID.
        let key = "com.audstreamer.devicehelper.deviceID"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
        #else
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else {
            preconditionFailure("Cannot get identifierForVendor")
        }
        return deviceID
        #endif
    }

    public static var deviceName: String {
        #if os(watchOS)
        // WKInterfaceDevice has no 'name'; use model + systemName as a stable, non-identifying label
        let d = WKInterfaceDevice.current()
        return "\(d.model) (\(d.systemName))"
        #else
        return UIDevice.current.name
        #endif
    }

    public static var deviceModel: String {
        #if os(watchOS)
        return WKInterfaceDevice.current().model
        #else
        return UIDevice.current.model
        #endif
    }
}

// MARK: - Public methods

extension DeviceHelper {
    public static func isDeviceIDCurrent(_ deviceID: String?) -> Bool {
        Self.deviceID == deviceID
    }
}
