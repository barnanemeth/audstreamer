//
//  Environment+Validation.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 16..
//

import SwiftUI

struct IndirectValidationEnvironmentKey: EnvironmentKey {
    static let defaultValue = ValidationResult.valid
}

struct DirectValidationEnvironmentKey: EnvironmentKey {
    static let defaultValue = ValidationResult.valid
}

extension EnvironmentValues {
    var indirectValidationResult: ValidationResult {
        get { self[IndirectValidationEnvironmentKey.self] }
        set { self[IndirectValidationEnvironmentKey.self] = newValue }
    }

    var directValidationResult: ValidationResult {
        get { self[DirectValidationEnvironmentKey.self] }
        set { self[DirectValidationEnvironmentKey.self] = newValue }
    }
}
