//
//  Authorization.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 17..
//

import Foundation
import Combine

public protocol Authorization {
    func authorize() -> AnyPublisher<Data, Error>
    func checkAuthorizationStatus(for userID: String) -> AnyPublisher<AuthorizationState, Error>
}
