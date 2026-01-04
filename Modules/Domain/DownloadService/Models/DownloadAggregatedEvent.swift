//
//  DownloadAggregatedEvent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Foundation

import Common

public struct DownloadAggregatedEvent: Hashable, Equatable {

    // MARK: Properties

    public let items: [Downloadable]
    public let progress: Progress
    public let userInfo: [String: Any]?

    public var isSilentDownloading: Bool {
        guard let isSilentDownloading = userInfo?[UserInfoKeys.isSilentDownloading] as? Bool else { return false }
        return isSilentDownloading
    }

    // MARK: Init

    public init(items: [Downloadable], progress: Progress, userInfo: [String : Any]? = nil) {
        self.items = items
        self.progress = progress
        self.userInfo = userInfo
    }

    // MARK: Hashable & Equatable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(items.map(\.id))
        hasher.combine(progress.fractionCompleted)
    }

    public static func == (_ lhs: DownloadAggregatedEvent, _ rhs: DownloadAggregatedEvent) -> Bool {
        lhs.items.map(\.id) == rhs.items.map(\.id) && lhs.progress.fractionCompleted == rhs.progress.fractionCompleted
    }
}

// MARK: - LoadingAggregatedEvent

extension DownloadAggregatedEvent: LoadingAggregatedEvent {
    public var progressValue: Double { progress.fractionCompleted }
    public var isFinished: Bool { progress.isFinished }
    public var numberOfItems: Int { items.count }
}
