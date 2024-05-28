//
//  Authorization.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 17..
//

import Foundation
import Combine

protocol Authorization {
    func authorize() -> AnyPublisher<Data, Error>
    func checkAuthorizationStatus(for userID: String) -> AnyPublisher<AuthorizationState, Error>
}

enum AuthorizationState {
    case authorized
    case revoked
    case notFound
    case transferred
}

enum AuthorizationError: Error {
    case missingCredential
    case userCanceled
}
