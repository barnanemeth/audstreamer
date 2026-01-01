//
//  LoadingWidget.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 01..
//

import SwiftUI

import Lottie

struct LoadingWidget: View {

    // MARK: Constants

    private enum Constant {
        static let height: CGFloat = 60
        static let maxWidth: CGFloat = 320
        static let animationPath = Bundle.main.url(forResource: "DownloadAnimation", withExtension: "json")?.path ?? ""
        static let finishedAnimationFrame: CGFloat = 0.8
        static let dismissOffset: CGFloat = 178
        static let animation: Animation = .spring(duration: 0.3, bounce: 0.6, blendDuration: .zero)
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
                    .background(Asset.Colors.background.swiftUIColor)
                    .clipShape(Capsule())
                    .shadow(color: Asset.Colors.shadow.swiftUIColor, radius: 10)
                }
                .buttonStyle(.plain)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top),
                        removal: .offset(y: -Constant.dismissOffset).combined(with: .opacity)
                    )
                )
                .allowsHitTesting(onTap != nil)
            }
        }
        .animation(Constant.animation, value: viewModel.isVisible)
        .task { await viewModel.subscribe() }
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
                    .foregroundStyle(Asset.Colors.error.swiftUIColor)
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
        .foregroundStyle(Asset.Colors.label.swiftUIColor)
        .padding(.vertical, 4)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
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
