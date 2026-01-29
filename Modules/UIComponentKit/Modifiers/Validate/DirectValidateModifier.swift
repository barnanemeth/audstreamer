//
//  DirectValidateModifier.swift
//  UI
//
//  Created by Barna Nemeth on 2024. 12. 16..
//

import SwiftUI

struct DirectValidateModifier: ViewModifier {

    // MARK: Private properties

    @Binding private var validationResult: ValidationResult
    @FocusState private var isFocused

    // MARK: Init

    init(result: Binding<ValidationResult>) {
        self._validationResult = result
    }

    // MARK: UI

    func body(content: Content) -> some View {
        content
            .environment(\.directValidationResult, validationResult)
    }
}
