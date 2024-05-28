//
//  FileTransferItem.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 01/11/2023.
//

import Foundation

struct FileTransferAggregatedProgress {

    // MARK: Properties

    let numberOfItems: Int
    let progress: Double

    var isFinished: Bool {
        progress == 1 || numberOfItems == .zero
    }
}

// MARK: - Hashable & Equatable

extension FileTransferAggregatedProgress: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(numberOfItems)
        hasher.combine(progress)
    }

    static func == (_ lhs: FileTransferAggregatedProgress, _ rhs: FileTransferAggregatedProgress) -> Bool {
        lhs.numberOfItems == rhs.numberOfItems && lhs.progress == rhs.progress
    }
}
