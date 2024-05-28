//
//  FileTransferWidgetViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 01/11/2023.
//

import UIKit
import Combine

final class FileTransferWidgetViewModel {

    // MARK: Dependencies

    @Injected private var watchConnevtivityService: WatchConnectivityService

    // MARK: Properites

    @Published var isOpened = false
    var state: AnyPublisher<FileTransferWidgetState?, Never> {
        watchConnevtivityService.getAggregatedFileTransferProgress()
            .map { aggregatedProgress -> FileTransferWidgetState in
                aggregatedProgress.isFinished ?
                    .finished(progress: aggregatedProgress) :
                    .inProgress(progress: aggregatedProgress)
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

    // MARK: Init

    init() {
        subscribeToOpenedState()
        subscribeToFinishedState()
    }
}

// MARK: - Helpers

extension FileTransferWidgetViewModel {
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
                case .inProgress: return true
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
            .filter { state in
                guard case .finished = state else { return false }
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
