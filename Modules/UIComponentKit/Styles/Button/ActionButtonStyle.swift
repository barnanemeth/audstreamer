//
//  ActionButtonStyle.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 30..
//

import SwiftUI

public struct ActionButtonStyle: ButtonStyle {
    public init() { }
}

// MARK: - View

extension ActionButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .semibold))
            .tint(Asset.Colors.labelLight.swiftUIColor)
            .foregroundColor(Asset.Colors.labelLight.swiftUIColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Asset.Colors.accentPrimary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
