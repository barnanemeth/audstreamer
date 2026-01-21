//
//  Authorization.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 17..
//

import Foundation
import Combine

protocol Authorization {
    func authorize() -> AnyPublisher<String, Error>
}
