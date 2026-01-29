//
//  ValidationResult.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 16..
//

import Foundation

public enum ValidationResult: Equatable {
    case valid
    case invalid(message: String? = nil)
}
