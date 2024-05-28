//
//  FilterService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import Foundation
import Combine

protocol FilterService {
    func getAttributes() -> AnyPublisher<[FilterAttribute], Error>
    func setAttribute(_ attribute: FilterAttribute) -> AnyPublisher<Void, Error>
}

enum FilterAttributeType: CaseIterable {
    case favorites
    case downloads
    case watch
}

struct FilterAttribute: Hashable {
    let type: FilterAttributeType
    var isActive: Bool

    init(type: FilterAttributeType, isActive: Bool = false) {
        self.type = type
        self.isActive = isActive
    }
}
