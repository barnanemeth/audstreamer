//
//  DownloadingCellItem.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 12. 02..
//

import Foundation
import Combine

struct DownloadingCellItem {

    // MARK: Properties

    let item: Downloadable
    let eventPublisher: AnyPublisher<DownloadEvent, Error>
    var isPaused = false

    var id: String { item.id }
    var title: String { item.title }

    // MARK: Init

    init(downloadable: Downloadable, eventPublisher: AnyPublisher<DownloadEvent, Error>) {
        self.item = downloadable
        self.eventPublisher = eventPublisher
    }
}

// MARK: - Hashable & Equatable

extension DownloadingCellItem: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isPaused)
    }

    static func == (_ lhs: DownloadingCellItem, _ rhs: DownloadingCellItem) -> Bool {
        lhs.id == rhs.id && lhs.isPaused == rhs.isPaused
    }
}
