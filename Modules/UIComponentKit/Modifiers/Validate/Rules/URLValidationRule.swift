//
//  URLValidationRule.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2026. 01. 29..
//

import Foundation

@Observable
public final class URLValidationRule: ValidationRule {

    // MARK: Properties

    public var errorMessage: String?
    public var isValid = false

    // MARK: Private properties

    private let regex: NSRegularExpression?

    // MARK: Init

    public init(errorMessage: String) {
        do {
            self.regex = try NSRegularExpression(pattern: "[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)")
        } catch {
            self.regex = nil
        }
        self.errorMessage = errorMessage
    }

    // MARK: ValidationRule

    public func validate(_ text: String) -> Bool {
        guard let regex else { return false }
        let range = NSRange(location: .zero, length: text.utf16.count)
        let isValid = regex.firstMatch(in: text, options: [], range: range) != nil
        self.isValid = isValid
        return isValid
    }
}
