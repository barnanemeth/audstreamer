//
//  DashboardSectionHeader.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 26..
//

import SwiftUI

import UIComponentKit

internal import SFSafeSymbols

struct DashboardSection<Content: View>: View {

    // MARK: Constants

    private enum Constant {
        static var defaultHeaderHorizontalPadding: CGFloat { 16 }
        static var defaultContentHorizontalPadding: CGFloat { 16 }
    }

    // MARK: Private properties

    private let title: String
    private let buttonTitle: String?
    private let onButtonTap: (() -> Void)?
    private let headerHorizontalPadding: CGFloat
    private let contentHorizontalPadding: CGFloat
    @ViewBuilder private let content: () -> Content

    // MARK: Init

    init(title: String,
         headerHorizontalPadding: CGFloat = Constant.defaultHeaderHorizontalPadding,
         contentHorizontalPadding: CGFloat = Constant.defaultContentHorizontalPadding,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.buttonTitle = nil
        self.onButtonTap = nil
        self.headerHorizontalPadding = headerHorizontalPadding
        self.contentHorizontalPadding = contentHorizontalPadding
        self.content = content
    }

    init(title: String,
         buttonTitle: String,
         onButtonTap: @escaping () -> Void,
         headerHorizontalPadding: CGFloat = Constant.defaultHeaderHorizontalPadding,
         contentHorizontalPadding: CGFloat = Constant.defaultContentHorizontalPadding,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.buttonTitle = buttonTitle
        self.onButtonTap = onButtonTap
        self.headerHorizontalPadding = headerHorizontalPadding
        self.contentHorizontalPadding = contentHorizontalPadding
        self.content = content
    }

    // MARK: UI

    var body: some View {
        VStack(spacing: 16) {
            header
                .padding(.horizontal, headerHorizontalPadding)
            content()
                .padding(.horizontal, contentHorizontalPadding)
        }
    }
}

// MARK: - Helpers

extension DashboardSection {
    private var header: some View {
        HStack {
            Text(title)
                .font(.h4)
                .fontWeight(.semibold)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)

            Spacer()

            if let buttonTitle, let onButtonTap {
                Button {
                    onButtonTap()
                } label: {
                    Text(buttonTitle)
                    Image(systemSymbol: .chevronRight)
                }
                .buttonStyle(.text())
            }
        }
    }
}
