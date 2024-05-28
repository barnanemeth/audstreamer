//
//  DownloadItem.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 04..
//

import Foundation

struct DownloadItem: Downloadable {

    // MARK: Properties

    let id: String
    let title: String
    let remoteURL: URL
    let userInfo: [String: Any]?

    // MARK: Init

    init(from downloadable: Downloadable, userInfo: [String: Any]?) {
        self.id = downloadable.id
        self.title = downloadable.title
        self.remoteURL = downloadable.remoteURL
        self.userInfo = userInfo
    }
}

// MARK: - Hashable & Equatable

extension DownloadItem: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(remoteURL)
    }

    static func == (_ lhs: DownloadItem, _ rhs: DownloadItem) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.remoteURL == rhs.remoteURL
    }
}
