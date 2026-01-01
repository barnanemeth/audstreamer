//
//  FileTransferAggregatedProgress+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 01..
//

import Foundation

// MARK: - LoadingAggregatedEvent

extension FileTransferAggregatedProgress: LoadingAggregatedEvent {
    var progressValue: Double { progress }
}
