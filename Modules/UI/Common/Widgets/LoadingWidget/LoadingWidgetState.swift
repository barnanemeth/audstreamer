//
//  LoadingWidgetState.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 01..
//

import Foundation

enum LoadingWidgetState: Equatable {
    case indeterminate
    case inProgress(progress: Double, itemCount: Int)
    case finished(itemCount: Int)
    case failed(error: Error)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.inProgress(let lhsProgress, let lhsItemCount), .inProgress(let rhsProgress, let rhsItemCount)):
            return lhsProgress == rhsProgress && lhsItemCount == rhsItemCount
        case (.finished, .finished):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
