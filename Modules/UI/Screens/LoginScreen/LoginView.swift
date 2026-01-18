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
                .font(.title)
                .foregroundStyle(Asset.Colors.primary.swiftUIColor)

            Text(L10n.logInInfo)
                .font(.system(size: 17))
                .foregroundStyle(Asset.Colors.label.swiftUIColor)
                .multilineTextAlignment(.center)
        }
    }

    private var image: some View {
        Asset.Images.femaleMaleCircle.swiftUIImage
            .resizable()
            .foregroundStyle(Asset.Colors.primary.swiftUIColor)
            .frame(width: Constant.infoImageSize, height: Constant.infoImageSize)
    }

    private var buttons: some View {
        VStack(spacing: 32) {
            signInWithAppleButton

            Button(L10n.cancel) {
                viewModel.handleCancel()
            }
            .font(.headline)
            .foregroundStyle(Asset.Colors.primary.swiftUIColor)
        }
    }

    @ViewBuilder
    private var signInWithAppleButton: some View {
        let (foregroundColor, backgroundColor) = switch colorScheme {
        case .dark: (Asset.Colors.background.swiftUIColor, Asset.Colors.white.swiftUIColor)
        case .light: (Asset.Colors.white.swiftUIColor, Asset.Colors.label.swiftUIColor)
        @unknown default: (Asset.Colors.white.swiftUIColor, Asset.Colors.label.swiftUIColor)
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
