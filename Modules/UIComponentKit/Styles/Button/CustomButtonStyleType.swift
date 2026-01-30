//
//  CustomButtonStyleType.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 12..
//

import SwiftUI

internal import SFSafeSymbols

enum CustomButtonStyleType {
    case primary(size: ButtonSize, fill: Bool, icon: Image?, foregroundColor: Color?, backgroundColor: Color?)
    case secondary(size: ButtonSize, fill: Bool, icon: Image?)
    case text(size: ButtonSize, fill: Bool, icon: Image?)
    case symbol(fill: Bool)

    var size: ButtonSize {
        switch self {
        case let .primary(size, _, _, _, _): size
        case let .secondary(size, _, _): size
        case let .text(size, _, _): size
        case .symbol: .medium
        }
    }

    var fill: Bool {
        switch self {
        case let .primary(_, fill, _, _, _): fill
        case let .secondary(_, fill, _): fill
        case let .text(_, fill, _): fill
        case let .symbol(fill): fill
        }
    }

    var icon: Image? {
        switch self {
        case let .primary(_, _, icon, _, _): icon
        case let .secondary(_, _, icon): icon
        case let .text(_, _, icon): icon
        case .symbol: nil
        }
    }

    var borderWidth: CGFloat? {
        switch self {
        case let .secondary(size, _, _): size.borderWidth
        case .primary, .text, .symbol: nil
        }
    }

    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        switch self {
        case let .primary(_, _, _, overrideColor, _):
            if let overrideColor {
                return isPressed ? overrideColor.darken(by: 0.25) : overrideColor
            }

            guard isEnabled else { return Asset.Colors.labelSecondary.swiftUIColor }
            return Asset.Colors.labelLight.swiftUIColor
        case .secondary:
            guard isEnabled else { return Asset.Colors.surfaceMuted.swiftUIColor }
            return isPressed ? Asset.Colors.labelSecondary.swiftUIColor : Asset.Colors.labelPrimary.swiftUIColor
        case .text:
            guard isEnabled else { return Asset.Colors.surfaceMuted.swiftUIColor }
            return isPressed ? Asset.Colors.accentPrimaryPressed.swiftUIColor : Asset.Colors.accentPrimary.swiftUIColor
        case .symbol:
            guard isEnabled else { return Asset.Colors.labelSecondary.swiftUIColor }
            return Asset.Colors.labelLight.swiftUIColor
        }
    }

    func backgroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        switch self {
        case let .primary(_, _, _, _, overrideColor):
            if let overrideColor {
                return isPressed ? overrideColor.darken(by: 0.25) : overrideColor
            }

            guard isEnabled else { return Asset.Colors.surfaceMuted.swiftUIColor }
            return isPressed ? Asset.Colors.accentPrimaryPressed.swiftUIColor : Asset.Colors.accentPrimary.swiftUIColor
        case .symbol:
            guard isEnabled else { return Asset.Colors.surfaceMuted.swiftUIColor }
            return isPressed ? Asset.Colors.accentPrimaryPressed.swiftUIColor : Asset.Colors.accentPrimary.swiftUIColor
        case .secondary:
            guard isEnabled else { return Asset.Colors.surfaceMuted.swiftUIColor }
            return Asset.Colors.surfaceMuted.swiftUIColor
        case .text:
            return .clear
        }
    }
}
