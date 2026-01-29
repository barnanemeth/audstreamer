//
//  IndirectValidateModifiers.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2026. 01. 28..
//

import SwiftUI

struct IndirectValidateModifier: ViewModifier {

    // MARK: Private properties

    private let rule: any ValidationRule
    @Binding var text: String

    @FocusState private var isFocused
    @State private var validationResult: ValidationResult = .valid

    // MARK: Init

    init(rule: any ValidationRule, text: Binding<String>) {
        self.rule = rule
        self._text = text
    }

    // MARK: UI

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: text) { initial, newValue in
                guard initial != newValue else { return }
                update()
            }
            .onChange(of: isFocused) { _, newValue in
                guard !newValue else { return }
                update()
            }
            .environment(\.indirectValidationResult, validationResult)
    }

    // MARK: Helpers

    private func update() {
        validationResult = if rule.validate(text) {
            .valid
        } else {
            .invalid(message: rule.errorMessage)
        }
    }
}
