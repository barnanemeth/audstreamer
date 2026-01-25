//
//  LoadingWidget.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 01..
//

import SwiftUI

import UIComponentKit

internal import Lottie
internal import SFSafeSymbols

struct LoadingWidget: View {

    // MARK: Constants

    private enum Constant {
        static let height: CGFloat = 60
        static let maxWidth: CGFloat = 320
        static let animationPath = Bundle.main.url(forResource: "DownloadAnimation", withExtension: "json")?.path ?? ""
        static let finishedAnimationFrame: CGFloat = 0.8
        static let dismissOffset: CGFloat = 178
        static let animation: Animation = .spring(duration: 0.3, bounce: 0.6, blendDuration: .zero)
        static let minimumDragDistance: CGFloat = 32
        static let minimumDismissVelocity: CGFloat = 200
    }

    // MARK: Dependencies

    @State var viewModel: LoadingWidgetViewModel

    // MARK: Properties

    var onTap: (() -> Void)?

    // MARK: UI

    var body: some View {
        Group {
            if viewModel.isVisible {
                Button {
                    onTap?()
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        progressIndicator
                        titles
                    }
                    .frame(height: Constant.height)
                    .frame(maxWidth: Constant.maxWidth)
                    .clipShape(Capsule())
                    .glassEffect(.regular, in: .capsule)
                }
                .disabled(onTap == nil) // TODO: button style
                .buttonStyle(.borderless)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top),
                        removal: .offset(y: -Constant.dismissOffset).combined(with: .opacity)
                    )
                )
                .highPriorityGesture(dragGesture)
            }
        }
        .animation(Constant.animation, value: viewModel.isVisible)
    }
}

// MARK: - Helpers

extension LoadingWidget {
    @ViewBuilder
    private var progressIndicator: some View {
        Group {
            switch viewModel.state {
            case .indeterminate:
                progressAnimationView(with: .zero)
            case let .inProgress(progress, _):
                progressAnimationView(with: progress * Constant.finishedAnimationFrame)
            case .finished:
                finishedAnimationView
            case .failed:
                Image(systemSymbol: .xmarkCircle)
                    .resizable()
                    .fontWeight(.thin)
                    .foregroundStyle(Asset.Colors.State.error.swiftUIColor)
                    .padding(2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func progressAnimationView(with progress: Double) -> some View {
        LottieView(animation: .filepath(Constant.animationPath))
            .playbackMode(.paused(at: .progress(progress)))
            .aspectRatio(1, contentMode: .fit)
    }

    private var finishedAnimationView: some View {
        LottieView(animation: .filepath(Constant.animationPath))
            .playbackMode(.playing(.fromProgress(Constant.finishedAnimationFrame, toProgress: 1, loopMode: .playOnce)))
    }

    private var titles: some View {
        VStack(alignment: .leading) {
            Text(viewModel.title ?? "")
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)

            Text(viewModel.subtitle ?? "")
                .font(.system(size: 12, weight: .regular))
        }
        .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
        .padding(.vertical, 4)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: Constant.minimumDragDistance)
            .onEnded { handleDragGestureEnd($0) }
    }

    private func handleDragGestureEnd(_ value: DragGesture.Value) {
        guard value.startLocation.y > value.location.y &&
                value.velocity.height < -Constant.minimumDismissVelocity else {
            return
        }
        viewModel.dismiss()
    }
}

// MARK: - Preview

#Preview {
    struct Screen: View {
        @State var isVisible = false

        var body: some View {
            VStack {
                Text("Loadingwidget")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Button("Toggle") { isVisible.toggle() }
            }
            .padding()
            .overlay(alignment: .top) {
                LoadingWidget(viewModel: DownloadingWidgetViewModel()) {}
            }
        }
    }
    return Screen()
}
