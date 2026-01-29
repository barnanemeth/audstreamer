//
//  NonEmptyValidationRule.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 16..
//

import Foundation

import Common

@Observable
final public class NonEmptyValidationRule: ValidationRule {

    // MARK: Properties

    public var errorMessage: String?
    public var isValid = false

    // MARK: Init

    public init(errorMessage: String? = "Empty") {
        self.errorMessage = errorMessage
    }

    // MARK: ValidationRule

    public func validate(_ text: String) -> Bool {
        let isValid = !text.isEmpty
        self.isValid = isValid
        return isValid
    }
}
