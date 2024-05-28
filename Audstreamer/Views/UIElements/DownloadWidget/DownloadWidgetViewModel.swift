//
//  DownloadWidgetViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 05..
//

import UIKit
import Combine

final class DownloadWidgetViewModel {

    // MARK: Dependencies

    @Injected private var downloadService: DownloadService

    // MARK: Properites

    @Published var isOpened = false
    var state: AnyPublisher<DownloadWidgetState?, Never> {
        let aggregatedEvent = downloadService.getAggregatedEvent()
            .filter { !$0.isSilentDownloading }

        return Publishers.CombineLatest(aggregatedEvent, singleError)
            .map { [unowned self] in self.getState(aggregatedEvent: $0, singleError: $1) }
            .removeDuplicates()
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    private var singleError: AnyPublisher<Error?, Error> {
        downloadService.getEvent()
            .map { event in
                switch event {
                case let .error(_, error): return error
                default: return nil
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: Init

    init() {
        subscribeToOpenedState()
        subscribeToFinishedState()
    }
}

// MARK: - Helpers

extension DownloadWidgetViewModel {
    private func getState(aggregatedEvent: DownloadAggregatedEvent, singleError: Error?) -> DownloadWidgetState {
        if let error = singleError {
            return .error(error: error)
        }
        if aggregatedEvent.progress.isFinished {
            return .finished(items: aggregatedEvent.items)
        }
        return .inProgress(progress: aggregatedEvent.progress, items: aggregatedEvent.items)
    }

    private func subscribeToOpenedState() {
        state
            .filter { event in
                switch event {
                case .inProgress, .error: return true
                default: return false
                }
            }
            .map { _ in true }
            .replaceError(with: false)
            .assign(to: \.isOpened, on: self, ownership: .unowned)
            .store(in: &cancellables)
    }

    private func subscribeToFinishedState() {
        state
            .filter { event in
                guard case .finished = event else { return false }
                return true
            }
            .sink { [unowned self] _ in self.triggerSuccessFeedback() }
            .store(in: &cancellables)
    }

    private func triggerSuccessFeedback() {
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
}
