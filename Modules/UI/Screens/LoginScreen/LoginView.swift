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
        static let animationPeriod: TimeInterval = 2
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
        VStack(spacing: 24) {
            Spacer()
            image
            Spacer()
            title
            checkList
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
    private var image: some View {
        TimelineView(.periodic(from: .now, by: Constant.animationPeriod)) { context in
            Image(systemSymbol: symbol(for: context.date))
                .font(.system(size: 88))
                .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)
                .contentTransition(.symbolEffect(.replace.byLayer))
        }
        .frame(height: 100)
    }

    private var title: some View {
        VStack(spacing: 12) {
            Text("Sign In")
                .font(.h2)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)

            Text("Sign in to sync your listening progress across devices and receive notifications for new episodes")
                .font(.bodyText)
                .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var checkList: some View {
        let list = [
            "Sync listening progress across devices",
            "Get notifications for new episodes"
        ]
        VStack(alignment: .leading, spacing: 8) {
            ForEach(list, id: \.self) { item in
                HStack(spacing: 8) {
                    Image(systemSymbol: .checkmarkCircleFill)
                        .foregroundStyle(Asset.Colors.accentPrimaryPressed.swiftUIColor)
                        .opacity(0.9)

                    Text(item)
                        .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                }
                .font(.bodySecondaryText)
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            signInWithAppleButton

            Button("Later") {
                viewModel.handleCancel()
            }
            .buttonStyle(.secondary(fill: true))
        }
    }

    @ViewBuilder
    private var signInWithAppleButton: some View {
        VStack(spacing: 16) {
            let (foregroundColor, backgroundColor): (Color, Color) = switch colorScheme {
            case .dark: (.black, .white)
            case .light: (.white, .black)
            @unknown default: (.black, .white)
            }
            AsyncButton("Sign in with Apple") {await viewModel.login() }
                .buttonStyle(
                    .primary(
                        fill: true,
                        icon: Image(systemSymbol: .appleLogo),
                        foregroundColor: foregroundColor,
                        backgroundColor: backgroundColor
                    )
                )
        }
    }

    private func symbol(for date: Date) -> SFSymbol {
        let t = date.timeIntervalSinceReferenceDate
        let step = Int(floor(t / Constant.animationPeriod))
        return if step.isMultiple(of: Int(Constant.animationPeriod)) {
            .ipadLandscapeAndIphone
        } else {
            .bellBadge
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView(shouldShowPlayerAtDismiss: false)
}
