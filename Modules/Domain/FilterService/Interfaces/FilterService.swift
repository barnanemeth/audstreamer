//
//  FilterService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import Foundation
import Combine

public protocol FilterService {
    func getAttributes() -> AnyPublisher<[FilterAttribute], Error>
    func setAttribute(_ attribute: FilterAttribute) -> AnyPublisher<Void, Error>
}
