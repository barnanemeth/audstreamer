//
//  PlayerWidget.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 18..
//

import SwiftUI

import SFSafeSymbols

struct PlayerWidget: View {

    // MARK: Constants

    private enum Constant {
        static let padding: CGFloat = 20
        static let remotePlayButtonSize: CGFloat = 24
        static let expandedPresentationDetent = PresentationDetent.height(198)
        static let collapsedPresentationDetent = PresentationDetent.height(88)
        static let titleGeometryID = "PlayerWidget.Title"
        static let playPauseButtonGeometryID = "PlayerWidget.PlayPauseButton"
    }

    // MARK: Dependencies

    @State private var viewModel = PlayerWidgetViewModel()

    // MARK: Properties

    let isLoading: Bool
    let onTitleTap: (Episode.ID) -> Void

    // MARK: Private properties

    @State private var presentationDetent = Constant.expandedPresentationDetent
    @Namespace private var namespace
    private var isEnabled: Bool {
        !isLoading && viewModel.isEnabled
    }
    private var titleText: String {
        if isLoading {
            String(repeating: L10n.mainTitle, count: 12)
        } else {
            viewModel.title ?? L10n.mainTitle
        }
    }
    private var isExpanded: Bool {
        presentationDetent == Constant.expandedPresentationDetent
    }

    // MARK: UI

    var body: some View {
        VStack(spacing: 8) {
            if isExpanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .padding(Constant.padding)
        .animation(.default, value: viewModel.activeRemotePlayingDeviceText)
        .animation(.default, value: isExpanded)
        .disabled(!isEnabled)
        .task { await viewModel.subscribe() }
        .presentationDetents([Constant.expandedPresentationDetent, Constant.collapsedPresentationDetent], selection: $presentationDetent)
        .presentationBackgroundInteraction(.enabled)
        .presentationSizing(.fitted)
        .interactiveDismissDisabled(true)
    }
}

// MARK: - Helpers

extension PlayerWidget {
    @ViewBuilder
    private var expandedContent: some View {
        remotePlaying
        titleAndRemotePlayButton
        controlButtons
        sliderAndTimeTexts
    }

    private var collapsedContent: some View {
        HStack {
            title
            playPauseButton
        }
    }

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

    private var titleAndRemotePlayButton: some View {
        HStack(spacing: 8) {
            title
            remotePlayButton
        }
    }

    private var title: some View {
        Button {
            guard let id = viewModel.episode?.id else { return }
            onTitleTap(id)
        } label: {
            Text(titleText)
                .font(.subheadline)
                .foregroundStyle(Asset.Colors.label.swiftUIColor)
                .lineLimit(3)
                .redacted(reason: isLoading ? .placeholder : [])
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .matchedGeometryEffect(id: Constant.titleGeometryID, in: namespace)
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
                    .font(.system(size: 24))
            }
            .frame(maxWidth: .infinity)

            playPauseButton
                .frame(maxWidth: .infinity)

            Button {
                viewModel.skipForward()
            } label: {
                Image(systemSymbol: ._10ArrowTriangleheadClockwise)
                    .font(.system(size: 24))
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Asset.Colors.primary.swiftUIColor)
        .opacity(isEnabled ? 1 : 0.5)
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
                .font(.system(size: 38))
                .contentTransition(.symbolEffect(.replace))
        }
        .matchedGeometryEffect(id: Constant.playPauseButtonGeometryID, in: namespace)
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
        Slider(value: binding) { isHighlighted in
            viewModel.isSliderHighlighted = isHighlighted
        }
    }

    private var timeTexts: some View {
        HStack {
            Text(viewModel.elapsedTimeText)
            Spacer()
            Text(viewModel.remainingTimeText)
        }
        .font(.caption2)
        .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
        .redacted(reason: isLoading ? .placeholder : [])
    }
}
