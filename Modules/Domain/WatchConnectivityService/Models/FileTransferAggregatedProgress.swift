//
//  FileTransferItem.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 01/11/2023.
//

import Foundation

public struct FileTransferAggregatedProgress {

    // MARK: Properties

    public let numberOfItems: Int
    public let progress: Double

    public var isFinished: Bool {
        progress == 1 || numberOfItems == .zero
    }

    // MARK: Init

    public init(numberOfItems: Int, progress: Double) {
        self.numberOfItems = numberOfItems
        self.progress = progress
    }
}

// MARK: - Hashable & Equatable

extension FileTransferAggregatedProgress: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(numberOfItems)
        hasher.combine(progress)
    }

    public static func == (_ lhs: FileTransferAggregatedProgress, _ rhs: FileTransferAggregatedProgress) -> Bool {
        lhs.numberOfItems == rhs.numberOfItems && lhs.progress == rhs.progress
    }
}

// MARK: - LoadingAggregatedEvent

extension FileTransferAggregatedProgress: LoadingAggregatedEvent {
    public var progressValue: Double { progress }
}
