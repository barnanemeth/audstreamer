//
//  LoadingWidgetViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 01..
//

import Foundation
import Combine
import UIKit

@Observable
class LoadingWidgetViewModel: ViewModel {

    // MARK: Private properties

    @ObservationIgnored private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

    // MARK: Overridable properties

    @ObservationIgnored var defaultTitle: String? {
        nil
    }

    @ObservationIgnored var statePublisher: AnyPublisher<LoadingWidgetState?, Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    @ObservationIgnored var singleError: AnyPublisher<Error?, Error> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    // MARK: Properties

    private(set) var isVisible = false
    private(set) var state: LoadingWidgetState = .indeterminate
    private(set) var title: String?
    private(set) var subtitle: String?

    // MARK: - Overridable

    func getState(aggregatedEvent: any LoadingAggregatedEvent, singleError: Error?) -> LoadingWidgetState {
        if let error = singleError {
            .failed(error: error)
        } else if aggregatedEvent.isFinished {
            .finished(itemCount: aggregatedEvent.numberOfItems)
        } else {
            .inProgress(progress: aggregatedEvent.progressValue, itemCount: aggregatedEvent.numberOfItems)
        }
    }

    func getSubtitleText(progress: Double?, itemCount: Int, isFinished: Bool) -> String? {
        nil
    }
}

// MARK: - View model

extension LoadingWidgetViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.updateState() }
            taskGroup.addTask { await self.updateVisibleState() }
            taskGroup.addTask { await self.updateTitles() }
        }
    }
}

// MARK: - Helpers

extension LoadingWidgetViewModel {
    @MainActor
    private func updateState() async {
        for await state in statePublisher.asAsyncStream() {
            self.state = state ?? .indeterminate
        }
    }

    @MainActor
    private func updateVisibleState() async {
        let publisher = statePublisher
            .map { event in
                switch event {
                case .inProgress, .failed: true
                default: false
                }
            }
            .removeDuplicates()
            .replaceError(with: false)

        for await isVisible in publisher.asAsyncStream() {
            if isVisible {
                self.isVisible = true
            } else {
                try? await Task.sleep(for: .seconds(1))
                self.isVisible = false
            }
        }
    }

    @MainActor
    private func updateTitles() async {
        for await state in statePublisher.asAsyncStream() {
            switch state {
            case let .inProgress(progress, itemCount):
                title = defaultTitle
                subtitle = getSubtitleText(progress: progress, itemCount: itemCount, isFinished: false)
            case let .finished(itemCount):
                subtitle = getSubtitleText(progress: nil, itemCount: itemCount, isFinished: true)
            case let .failed(error):
                title = L10n.error
                subtitle = error.localizedDescription
            default:
                continue
            }
        }
    }

    private func triggerSuccessFeedback() {
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
}
