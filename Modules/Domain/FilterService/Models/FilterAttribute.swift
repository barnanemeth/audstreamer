//
//  FilterAttribute.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

public struct FilterAttribute: Hashable {
    public let type: FilterAttributeType
    public var isActive: Bool

    public init(type: FilterAttributeType, isActive: Bool = false) {
        self.type = type
        self.isActive = isActive
    }
}
