//
//  PlayerView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 18..
//

import SwiftUI

import Common
import Domain
import UIComponentKit

internal import NukeUI
internal import SFSafeSymbols

struct PlayerView: View {

    // MARK: Constants

    private enum Constant {
        static let padding: CGFloat = 20
        static let remotePlayButtonSize: CGFloat = 24
    }

    // MARK: Dependencies

    @Bindable private var viewModel: PlayerViewModel

    // MARK: Private properties

    private var titleText: String {
        viewModel.title ?? L10n.mainTitle
    }

    // MARK: Init

    init() {
        _viewModel = Bindable(Resolver.resolve())
    }

    // MARK: UI

    var body: some View {
        VStack(spacing: 16) {
            remotePlaying
            image
            titleAndRemotePlayButton
            controlButtons
            sliderAndTimeTexts
        }
        .padding(Constant.padding)
        .animation(.default, value: viewModel.activeRemotePlayingDeviceText)
        .disabled(!viewModel.isEnabled)
        .task(id: "PlayerViewModel.SubscriptionTask") { await viewModel.subscribe() }
        .presentationBackgroundInteraction(.enabled)
    }
}

// MARK: - Helpers

extension PlayerView {
    @ViewBuilder
    private var remotePlaying: some View {
        if let text = viewModel.activeRemotePlayingDeviceText {
            ZStack {
                Text(text)
                    .font(.system(size: 11))
                    .foregroundStyle(Asset.Colors.white.swiftUIColor)
                    .padding(.top, 14)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity)
            }
            .pulsingBackground(from: Asset.Colors.primary.swiftUIColor, to: Asset.Colors.secondary.swiftUIColor)
            .padding(.horizontal, -20)
            .padding(.top, -Constant.padding)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var image: some View {
        LazyImage(url: viewModel.episode?.image) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
        .padding()
    }

    private var titleAndRemotePlayButton: some View {
        HStack(spacing: 8) {
            title
            remotePlayButton
        }
    }

    private var title: some View {
        VStack(spacing: 8) {
            Text(viewModel.episode?.podcastTitle.uppercased() ?? "")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(titleText)
                .font(.subheadline)
                .foregroundStyle(Asset.Colors.label.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var remotePlayButton: some View {
        Menu {
            remotePlayButtonMenuContent
        } label: {
            Image(systemSymbol: .airplayAudio)
                .font(.system(size: Constant.remotePlayButtonSize, weight: .semibold))
                .foregroundStyle(Asset.Colors.primary.swiftUIColor)
                .overlay(alignment: .topTrailing) {
                    if let count = viewModel.activeDevicesCount {
                        Badge(text: count.description)
                    }
                }
        }
        .disabled(viewModel.activeDevicesCount == nil)
        .opacity(viewModel.activeDevicesCount == nil ? 0.5 : 1)
        .keyframeAnimator(
            initialValue: 1,
            trigger: viewModel.activeDevicesCount,
            content: { $0.scaleEffect($1) },
            keyframes: { _ in
                if viewModel.activeDevicesCount != nil {
                    CubicKeyframe(1.3, duration: 0.25)
                    CubicKeyframe(1, duration: 0.25)
                } else {
                    LinearKeyframe(1, duration: 1)
                }
            }
        )
    }

    private var remotePlayButtonMenuContent: some View {
        ForEach(viewModel.devices) { device in
            let symbol: SFSymbol = switch device.type {
            case .iPhone: .iphone
            case .iPad: .ipad
            default: .questionmarkCircle
            }
            let isOn = Binding<Bool>(
                get: { viewModel.activeDeviceID == device.id },
                set: { isOn in
                    guard isOn else { return }
                    viewModel.setActiveDeviceID(device.id)
                }
            )
            Toggle(device.name, systemImage: symbol.rawValue, isOn: isOn)
        }
    }

    private var controlButtons: some View {
        HStack {
            Button {
                viewModel.skipBackward()
            } label: {
                Image(systemSymbol: ._10ArrowTriangleheadCounterclockwise)
                    .font(.system(size: 28))
            }
            .frame(maxWidth: .infinity)

            playPauseButton
                .frame(maxWidth: .infinity)

            Button {
                viewModel.skipForward()
            } label: {
                Image(systemSymbol: ._10ArrowTriangleheadClockwise)
                    .font(.system(size: 28))
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Asset.Colors.primary.swiftUIColor)
    }

    private var playPauseButton: some View {
        Button {
            viewModel.playPlause()
        } label: {
            let symbol: SFSymbol = if viewModel.isPlaying {
                .pauseCircleFill
            } else {
                .playCircleFill
            }
            Image(systemSymbol: symbol)
                .font(.system(size: 42))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(Asset.Colors.primary.swiftUIColor)
        }
    }

    private var sliderAndTimeTexts: some View {
        VStack(spacing: 4) {
            slider
            timeTexts
        }
    }

    @ViewBuilder
    private var slider: some View {
        let binding = Binding<Float>(
            get: { viewModel.isSliderHighlighted ? viewModel.currentSliderValue : viewModel.currentProgress },
            set: { viewModel.currentSliderValue = $0 }
        )
        UIComponentKit.Slider(value: binding) { isHighlighted in
            viewModel.isSliderHighlighted = isHighlighted
        }
        .tint(Asset.Colors.primary.swiftUIColor)
    }

    private var timeTexts: some View {
        HStack {
            Text(viewModel.elapsedTimeText)
            Spacer()
            Text(viewModel.remainingTimeText)
        }
        .font(.caption2)
        .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
    }
}
