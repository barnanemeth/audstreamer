//
//  AuthorizationError.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

public enum AuthorizationError: Error {
    case missingCredential
    case userCanceled
}
