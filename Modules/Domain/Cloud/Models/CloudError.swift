//
//  CloudError.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Foundation

import Common

public enum CloudError: Error, LocalizedError {
    case generalError(Error)
    case unavailableAccount

    public var errorDescription: String? {
        switch self {
        case let .generalError(error): return error.localizedDescription
        case .unavailableAccount: return L10n.appleIDRequired
        }
    }
}
