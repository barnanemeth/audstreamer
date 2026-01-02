//
//  DownloadEvent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Foundation

public enum DownloadEvent {

    // MARK: Cases

    case queued(item: Downloadable)
    case inProgress(item: Downloadable, progress: Progress)
    case finished(item: Downloadable)
    case error(item: Downloadable, error: Error)
    case deleted(item: Downloadable)

    // MARK: Properties

    public var item: Downloadable {
        switch self {
        case let .queued(item): return item
        case let .inProgress(item, _): return item
        case let .finished(item): return item
        case let .error(item, _): return item
        case let .deleted(item): return item
        }
    }
}
