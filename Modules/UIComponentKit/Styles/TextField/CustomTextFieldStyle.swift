//
//  CustomTextFieldStyle.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 13..
//

import SwiftUI

internal import SFSafeSymbols

public struct CustomTextFieldStyle {

    // MARK: Constants

    private enum Constant {
        static let spacing: CGFloat = 4
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
        static let iconSize: CGFloat = 22
        static let errorMessageHeight: CGFloat = 14
        static let invalidStateColor = Asset.Colors.State.error.swiftUIColor
    }

    // MARK: Private properties

    private let title: String?
    private let size: CustomTextFieldSize
    private let contentSize: CustomTextFieldContentSize
    private let icon: Image?
    private let shouldShowErrorMessage: Bool
    private let height: CGFloat?

    @FocusState private var isFocused
    @Environment(\.indirectValidationResult) private var indirectValidationResult
    @Environment(\.directValidationResult) private var directValidationResult
    @State private var aggregatedValidationResult: ValidationResult = .valid
    @Environment(\.isSelected) private var isSelected

    // MARK: Init

    public init(title: String?,
                size: CustomTextFieldSize,
                contentSize: CustomTextFieldContentSize,
                icon: Image?,
                shouldShowErrorMessage: Bool,
                height: CGFloat?
    ) {
        self.title = title
        self.size = size
        self.contentSize = contentSize
        self.icon = icon
        self.shouldShowErrorMessage = shouldShowErrorMessage
        self.height = height
    }
}

// MARK: - TextFieldStyle

extension CustomTextFieldStyle: TextFieldStyle {
    // swiftlint:disable:next identifier_name
    public func _body(configuration: TextField<_Label>) -> some View {
        VStack(spacing: Constant.spacing) {
            configure(configuration)
            errorMessage
        }
        .geometryGroup()
    }
}

// MARK: - Helpers

extension CustomTextFieldStyle {
    private func configure<Label: View>(_ configuration: Label) -> some View {
        HStack(spacing: Constant.spacing) {
            VStack(alignment: .leading, spacing: Constant.spacing) {
                if let title {
                    Text(title)
                        .font(.captionText)
                        .fontWeight(.semibold)
                        .foregroundStyle(placeholderTextColor)
                }

                configuration
                    .focused($isFocused)
                    .font(contentSize.font)
                    .foregroundStyle(tintColor)
                    .apply { view in
                        if height == nil {
                            view
                        } else {
                            view.frame(maxHeight: .infinity, alignment: .top)
                        }
                    }
            }

            if let icon {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .symbolEffect(
                        .wiggle,
                        options: .nonRepeating.speed(1.5),
                        isActive: isSymbolAnimationActive
                    )
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(placeholderTextColor)
                    .frame(width: Constant.iconSize)
            }
        }
        .padding(8)
        .frame(height: height ?? size.height)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: Constant.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Constant.cornerRadius)
                .stroke(borderColor, lineWidth: Constant.borderWidth)
                .padding(Constant.borderWidth)
        }
        .tint(tintColor)
        .animation(.default, value: isFocused)
        .animation(.default, value: isSelected)
        .onTapGesture { isFocused = true }
        .onChange(of: indirectValidationResult) { aggregatedValidationResult = $1 }
        .onChange(of: directValidationResult) { aggregatedValidationResult = $1 }
    }

    @ViewBuilder
    private var errorMessage: some View {
        if shouldShowErrorMessage {
            HStack(spacing: 4) {
                if case let .invalid(message) = aggregatedValidationResult, let message {
                    Image(systemSymbol: .exclamationmarkCircle)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                    Text(message)
                        .font(.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 4)
            .foregroundStyle(invalidStateColor)
            .frame(height: Constant.errorMessageHeight)
            .animation(.default, value: aggregatedValidationResult)
        }
    }

    private var primaryColor: Color {
        if aggregatedValidationResult == .valid {
            Asset.Colors.labelSecondary.swiftUIColor.opacity(0.5)
        } else {
            Constant.invalidStateColor
        }
    }

    private var placeholderTextColor: Color {
        isFocused || isSelected ? Asset.Colors.labelSecondary.swiftUIColor : Asset.Colors.labelSecondary.swiftUIColor.opacity(0.85)
    }

    private var backgroundColor: Color {
        primaryColor.opacity(0.25)
    }

    private var borderColor: Color {
        isFocused || isSelected ? primaryColor : Asset.Colors.labelSecondary.swiftUIColor.opacity(0.5)
    }

    private var tintColor: Color {
        isFocused || isSelected ? Asset.Colors.labelSecondary.swiftUIColor : Asset.Colors.labelSecondary.swiftUIColor
    }

    private var invalidStateColor: Color {
        isFocused || isSelected ? Constant.invalidStateColor : Constant.invalidStateColor
    }

    private var isSymbolAnimationActive: Bool {
        indirectValidationResult != .valid || directValidationResult != .valid
    }
}

// MARK: - TextFieldStyle

extension TextFieldStyle where Self == CustomTextFieldStyle {
    public static func custom(title: String? = nil,
                              size: CustomTextFieldSize = .normal,
                              contentSize: CustomTextFieldContentSize = .normal,
                              icon: Image? = nil,
                              shouldShowErrorMessage: Bool = true,
                              height: CGFloat? = nil) -> CustomTextFieldStyle {
        CustomTextFieldStyle(
            title: title,
            size: size,
            contentSize: contentSize,
            icon: icon,
            shouldShowErrorMessage: shouldShowErrorMessage,
            height: height
        )
    }
}

// MARK: - Preview

#Preview {
    struct CustonView: View {
        @FocusState private var isFocused
        @State private var text = ""

        var body: some View {
            TextField("", text: $text)
                .focused($isFocused)
                .textFieldStyle(.custom(title: "Email"))
                .validate($text, rule: NonEmptyValidationRule())

            TextField("", text: $text)
                .focused($isFocused)
                .textFieldStyle(.custom(contentSize: .large))
                .validate(.constant(.invalid(message: "Invalid")))

            Button("Focus") { isFocused = false }
        }
    }
    return CustonView()
}

