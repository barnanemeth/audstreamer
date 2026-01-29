//
//  ValidateModifier.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 16..
//

import SwiftUI

// MARK: - View

extension View {
    public func validate(_ text: Binding<String>, rule: any ValidationRule) -> some View {
        modifier(IndirectValidateModifier(rule: rule, text: text))
    }

    public func validate(_ result: Binding<ValidationResult>) -> some View {
        modifier(DirectValidateModifier(result: result))
    }
}
