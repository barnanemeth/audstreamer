//
//  FillWidthModifier.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI

struct FillWidthModifier: ViewModifier {
    let shouldFill: Bool

    func body(content: Content) -> some View {
        if shouldFill {
            content.frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

// MARK: - View

extension View {
    public func fillWidth(fill: Bool = true) -> some View {
        modifier(FillWidthModifier(shouldFill: fill))
    }
}
