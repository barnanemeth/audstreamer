//
//  CustomButtonStyle.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 11..
//

import SwiftUI

internal import SFSafeSymbols

public struct CustomButtonStyle: ButtonStyle {

    // MARK: Private properties

    private let type: CustomButtonStyleType

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isLoading) private var isLoading
    @State private var shouldShowIcon = true

    private var font: Font {
        switch type {
        case .symbol: .system(size: 22, weight: .semibold)
        default: type.size.font
        }
    }
    private var height: CGFloat {
        switch type {
        case .text: 28
        default: type.size.height
        }
    }
    private var horizontalPadding: CGFloat {
        switch type {
        case .text: 8
        default: type.size.horizontalPadding
        }
    }

    // MARK: Init

    init(type: CustomButtonStyleType) {
        self.type = type
    }
}

// MARK: - View

extension CustomButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: type.size.spacing) {
            if let icon = type.icon, shouldShowIcon {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: type.size.iconSize)
            }
            configuration.label
                .font(font)
                .frame(height: height)
                .fixedSize(horizontal: true, vertical: false)
                .tint(type.foregroundColor(isPressed: configuration.isPressed, isEnabled: isEnabled))
        }
        .fillWidth(fill: type.fill)
        .contentShape(RoundedRectangle(cornerRadius: type.size.cornerRadius))
        .padding(.horizontal, horizontalPadding)
        .foregroundStyle(type.foregroundColor(isPressed: configuration.isPressed, isEnabled: isEnabled))
        .background(type.backgroundColor(isPressed: configuration.isPressed, isEnabled: isEnabled))
        .clipShape(RoundedRectangle(cornerRadius: type.size.cornerRadius))
        .overlay { overlay(isPressed: configuration.isPressed, isEnabled: isEnabled) }
        .allowsHitTesting(!isLoading)
        .onChange(of: isLoading) { handleLoadingStateChange() }
        .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: - Helpers

extension CustomButtonStyle {
    @ViewBuilder
    private func overlay(isPressed: Bool, isEnabled: Bool) -> some View {
        if let borderWidth = type.borderWidth {
            RoundedRectangle(cornerRadius: type.size.cornerRadius)
                .stroke(type.foregroundColor(isPressed: isPressed, isEnabled: isEnabled), lineWidth: borderWidth)
                .padding(borderWidth)
        }
    }

    private func handleLoadingStateChange() {
        Task {
            if isLoading {
                try? await Task.sleep(for: .seconds(0.1))
                shouldShowIcon = false
            } else {
                shouldShowIcon = true
            }
        }
    }
}

// MARK: - ButtonStyle

extension ButtonStyle where Self == CustomButtonStyle {
    public static func primary(size: ButtonSize = .normal,
                               fill: Bool = false,
                               icon: Image? = nil,
                               backgroundColor: Color? = nil) -> CustomButtonStyle {
        CustomButtonStyle(type: .primary(size: size, fill: fill, icon: icon, backgroundColor: backgroundColor))
    }

    public static func secondary(size: ButtonSize = .normal,
                                 fill: Bool = false,
                                 icon: Image? = nil) -> CustomButtonStyle {
        CustomButtonStyle(type: .secondary(size: size, fill: fill, icon: icon))
    }

    public static func text(size: ButtonSize = .normal,
                            fill: Bool = false,
                            icon: Image? = nil) -> CustomButtonStyle {
        CustomButtonStyle(type: .text(size: size, fill: fill, icon: icon))
    }

    public static func symbol(fill: Bool = false) -> CustomButtonStyle {
        CustomButtonStyle(type: .symbol(fill: fill))
    }
}
