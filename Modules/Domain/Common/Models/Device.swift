//
//  Device.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 21..
//

import Foundation

public struct Device: Identifiable {

    // MARK: Enums

    public enum `Type`: String, Decodable {
        case iPhone
        case iPad
    }

    // MARK: Properties

    public let id: String
    public let name: String
    public let type: Type?
    public let connectionTime: Date

    // MARK: Init

    public init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let typeString = dictionary["type"] as? String,
              let connectionTime = dictionary["connectionTime"] as? Double else { return nil }
        self.id = id
        self.name = name
        self.type = Type(rawValue: typeString)
        self.connectionTime = Date(timeIntervalSince1970: connectionTime)
    }
}

// MARK: - Hashable & Equatable

extension Device: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (_ lhs: Device, _ rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Static methods

extension Device {
    public static func devicesFromData(_ data: [Any]) -> [Device] {
        guard let rootArray = data.first as? NSArray else { return [] }
        return rootArray.compactMap { item in
            guard let dictionary = item as? [String: Any] else { return nil }
            return Device(dictionary: dictionary)
        }
    }
}
