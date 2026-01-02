//
//  LoadingView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI

import Common
import UIComponentKit

internal import Lottie

struct LoadingView: ScreenView {

    // MARK: Constants

    private enum Constant {
        static let horizontalPadding: CGFloat = 36
    }

    // MARK: Dependencies

    @Bindable var viewModel: LoadingViewModel

    // MARK: UI

    var body: some View {
        VStack {
            Spacer()
            animation
            Spacer()
        }
        .overlay(alignment: .bottom) { label }
        .padding(.horizontal, Constant.horizontalPadding)
        .dialog(descriptor: $viewModel.currentlyShowedDialogDescriptor)
        .task { await viewModel.fetchData() }
    }
}

// MARK: - Helpers

extension LoadingView {
    @ViewBuilder
    private var animation: some View {
        let playbackMode: LottiePlaybackMode = if viewModel.isLoading {
            .playing(.fromProgress(.zero, toProgress: 1, loopMode: .loop))
        } else {
            .paused
        }

        LottieView(animation: .filepath(viewModel.animationPath))
            .playbackMode(playbackMode)
    }

    private var label: some View {
        Text(L10n.loading)
            .font(.callout)
            .foregroundStyle(Asset.Colors.label.swiftUIColor)
    }
}
