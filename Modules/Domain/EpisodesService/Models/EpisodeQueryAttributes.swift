//
//  EpisodeQueryAttributes.swift
//  Domain
//
//  Created by Barna Nemeth on 2026. 01. 09..
//

import Foundation

public struct EpisodeQueryAttributes {
    public let keyword: String?
    public let filterFavorites: Bool
    public let filterDownloads: Bool
    public let filterWatch: Bool

    public init(keyword: String?, filterFavorites: Bool, filterDownloads: Bool, filterWatch: Bool) {
        self.keyword = keyword
        self.filterFavorites = filterFavorites
        self.filterDownloads = filterDownloads
        self.filterWatch = filterWatch
    }
}

// MARK: - ExpressibleByNilLiteral

extension EpisodeQueryAttributes: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.keyword = nil
        self.filterFavorites = false
        self.filterDownloads = false
        self.filterWatch = false
    }
}
