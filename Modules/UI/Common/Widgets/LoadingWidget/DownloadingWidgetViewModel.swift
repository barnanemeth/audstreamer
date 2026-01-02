//
//  DownloadingWidgetViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 01..
//

import Foundation
import Combine

import Common
import Domain

final class DownloadingWidgetViewModel: LoadingWidgetViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var downloadService: DownloadService

    // MARK: Properties

    @ObservationIgnored override var defaultTitle: String? {
        L10n.downloading
    }

    @ObservationIgnored override var statePublisher: AnyPublisher<LoadingWidgetState?, Never> {
        let aggregatedEvent = downloadService.getAggregatedEvent()
            .filter { !$0.isSilentDownloading }

        return Publishers.CombineLatest(aggregatedEvent, singleError)
            .map { [unowned self] in getState(aggregatedEvent: $0, singleError: $1) }
            .removeDuplicates()
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    @ObservationIgnored override var singleError: AnyPublisher<Error?, Error> {
        downloadService.getEvent()
            .map { event in
                switch event {
                case let .error(_, error): return error
                default: return nil
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: Methods

    override func getSubtitleText(progress: Double?, itemCount: Int, isFinished: Bool) -> String? {
        if let progress {
            L10n.downloadingEpisodesCountPercentage(itemCount, Int(progress * 100))
        } else if isFinished {
            L10n.downloadingEpisodesCountPercentage(itemCount, 100)
        } else {
            nil
        }
    }
}
