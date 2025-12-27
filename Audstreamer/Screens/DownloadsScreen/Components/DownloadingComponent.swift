//
//  DownloadingComponent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 23..
//

import SwiftUI
import Combine

import Lottie

struct DownloadingComponent: View {

    // MARK: Constants

    private enum Constant {
        static let animationPath = Bundle.main.url(forResource: "DownloadAnimation", withExtension: "json")?.path ?? ""
        static let finishedAnimationFrame: CGFloat = 0.8
    }

    // MARK: Properties

    let data: Data

    // MARK: Private properties

    @SwiftUI.State private var downloadState: State = .queued

    // MARK: UI

    var body: some View {
        HStack(spacing: 8) {
            informations
            progressIndicator
        }
        .task(id: data.id) {
            do {
                for try await event in data.eventPublisher.values {
                    downloadState = switch event {
                    case .queued: .queued
                    case let .inProgress(_, progress): .inProgress(progress.fractionCompleted)
                    case let .error(_, error): .failed(error.localizedDescription)
                    case .finished, .deleted: .finished
                    }
                }
            } catch {
                print("error")
            }
        }
    }
}

// MARK: - Helpers

extension DownloadingComponent {
    private var informations: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.item.title)
                .lineLimit(1)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(stateText(for: downloadState))
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Asset.Colors.label.swiftUIColor)
    }

    @ViewBuilder
    private var progressIndicator: some View {
        Group {
            switch downloadState {
            case .queued:
                progressAnimationView(with: .zero)
            case let .inProgress(progress):
                progressAnimationView(with: progress * Constant.finishedAnimationFrame)
            case .finished:
                finishedAnimationView()
            case .failed:
                Image(systemSymbol: .xmarkCircle)
                    .resizable()
                    .fontWeight(.thin)
                    .foregroundStyle(Asset.Colors.error.swiftUIColor)
                    .padding(2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: 32)
    }

    func progressAnimationView(with progress: Double) -> some View {
        LottieView(animation: .filepath(Constant.animationPath))
            .playbackMode(.paused(at: .progress(progress)))
    }

    func finishedAnimationView() -> some View {
        LottieView(animation: .filepath(Constant.animationPath))
            .playbackMode(.playing(.fromProgress(Constant.finishedAnimationFrame, toProgress: 1, loopMode: .playOnce)))
    }

    private func stateText(for state: State) -> String {
        switch state {
        case .queued: L10n.downloadQueued
        case .inProgress: L10n.downloadInProgress
        case .finished: L10n.downloadFinished
        case let .failed(description): L10n.downloadError(description)
        }
    }
}

// MARK: - Data

extension DownloadingComponent {
    struct Data: Identifiable, Equatable, Hashable {
        let item: Downloadable
        var isPaused: Bool
        let eventPublisher: AnyPublisher<DownloadEvent, Error>

        var id: String { item.id }

        static func == (_ lhs: Self, _ rhs: Self) -> Bool {
            lhs.item.id == rhs.item.id &&
            lhs.isPaused == rhs.isPaused
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(item.id)
            hasher.combine(isPaused)
        }
    }

    private enum State: Equatable, Hashable {
        case queued
        case inProgress(Double)
        case finished
        case failed(String)
    }
}
