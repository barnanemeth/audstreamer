//
//  DownloadWidgetState.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 12. 01..
//

import Foundation

enum DownloadWidgetState: Equatable {
    case inProgress(progress: Progress, items: [Downloadable])
    case finished(items: [Downloadable])
    case error(error: Error)

    static func == (lhs: DownloadWidgetState, rhs: DownloadWidgetState) -> Bool {
        switch (lhs, rhs) {
        case (.inProgress(let lhsProgress, let lhsItems), .inProgress(let rhsProgress, let rhsItems)):
            return lhsProgress.fractionCompleted == rhsProgress.fractionCompleted && lhsItems.count == rhsItems.count
        case (.finished, .finished):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
