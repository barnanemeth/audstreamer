//
//  LoginView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI
 
import Common
import UIComponentKit

internal import SFSafeSymbols

struct LoginView: View {

    private enum Constant {
        static let infoImageSize: CGFloat = 240
    }

    // MARK: - Dependencies

    @State private var viewModel = LoginViewModel()

    // MARK: Private properties

    private let shouldShowPlayerAtDismiss: Bool
    @Environment(\.colorScheme) private var colorScheme

    // MARK: Init

    init(shouldShowPlayerAtDismiss: Bool) {
        self.shouldShowPlayerAtDismiss = shouldShowPlayerAtDismiss
    }

    // MARK: UI

    var body: some View {
        VStack {
            title
            Spacer()
            image
            Spacer()
            Spacer()
            buttons
        }
        .padding(.top, 56)
        .padding([.horizontal, .bottom])
        .background(Asset.Colors.surfaceBase.swiftUIColor)
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
        .interactiveDismissDisabled()
        .onAppear { viewModel.shouldShowPlayerAtDismiss = shouldShowPlayerAtDismiss }
    }
}

// MARK: - Helpers

extension LoginView {
    private var title: some View {
        VStack(spacing: 32) {
            Text(L10n.logIn)
                .font(.h1)
                .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)

            Text(L10n.logInInfo)
                .font(.system(size: 17))
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
        }
    }

    private var image: some View {
        Asset.Images.femaleMaleCircle.swiftUIImage
            .resizable()
            .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)
            .frame(width: Constant.infoImageSize, height: Constant.infoImageSize)
    }

    private var buttons: some View {
        VStack(spacing: 32) {
            signInWithAppleButton

            Button(L10n.cancel) {
                viewModel.handleCancel()
            }
            .buttonStyle(.text())
        }
    }

    @ViewBuilder
    private var signInWithAppleButton: some View {
        let (foregroundColor, backgroundColor): (Color, Color) = switch colorScheme {
        case .dark: (.black, .white)
        case .light: (.white, .black)
        @unknown default: (.black, .white)
        }

        AsyncButton {
            await viewModel.login()
        } label: {
            Spacer()
            Image(systemSymbol: .appleLogo)
            Text(L10n.signInWithApple)
            Spacer()
        }
        .fillWidth()
        .padding()
        .fontWeight(.semibold)
        .foregroundStyle(foregroundColor)
        .tint(foregroundColor)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(height: 44)
    }
}
