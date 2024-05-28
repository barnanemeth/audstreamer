//
//  FileTransferWidgetState.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 01/11/2023.
//

import Foundation

enum FileTransferWidgetState: Equatable {
    case inProgress(progress: FileTransferAggregatedProgress)
    case finished(progress: FileTransferAggregatedProgress)

    static func == (lhs: FileTransferWidgetState, rhs: FileTransferWidgetState) -> Bool {
        switch (lhs, rhs) {
        case (.inProgress(let lhsProgress), .inProgress(let rhsProgress)):
            return lhsProgress == rhsProgress
        case (.finished(let lhsProgress), .finished(let rhsProgress)):
            return lhsProgress == rhsProgress
        default:
            return false
        }
    }
}
