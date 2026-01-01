//
//  FileTransferWidgetViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 01..
//

import Foundation
import Combine

final class FileTransferWidgetViewModel: LoadingWidgetViewModel {

    // MARK: Dependencies

    @Injected private var watchConnevtivityService: WatchConnectivityService

    // MARK: Properties

    @ObservationIgnored override var defaultTitle: String? {
        L10n.transferring
    }

    @ObservationIgnored override var statePublisher: AnyPublisher<LoadingWidgetState?, Never> {
        watchConnevtivityService.getAggregatedFileTransferProgress()
            .map { aggregatedProgress -> LoadingWidgetState in
                if aggregatedProgress.isFinished {
                    .finished(itemCount: aggregatedProgress.numberOfItems)
                } else {
                    .inProgress(progress: aggregatedProgress.progressValue, itemCount: aggregatedProgress.numberOfItems)
                }
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    // MARK: Methods

    override func getSubtitleText(progress: Double?, itemCount: Int, isFinished: Bool) -> String? {
        if let progress {
            L10n.transferringEpisodesCountPercentage(itemCount, Int(progress * 100))
        } else if isFinished {
            L10n.transferringEpisodesCountPercentage(itemCount, 100)
        } else {
            nil
        }
    }
}
