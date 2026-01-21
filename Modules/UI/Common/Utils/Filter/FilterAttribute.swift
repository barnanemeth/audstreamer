//
//  FilterAttribute.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

struct FilterAttribute: Hashable {
    let type: FilterAttributeType
    var isActive: Bool

    init(type: FilterAttributeType, isActive: Bool = false) {
        self.type = type
        self.isActive = isActive
    }
}
