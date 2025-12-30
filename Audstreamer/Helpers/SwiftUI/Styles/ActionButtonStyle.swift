//
//  ActionButtonStyle.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 30..
//

import SwiftUI

struct ActionButtonStyle: ButtonStyle { }

// MARK: - View

extension ActionButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .semibold))
            .tint(Asset.Colors.white.swiftUIColor)
            .foregroundColor(Asset.Colors.white.swiftUIColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Asset.Colors.primary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
