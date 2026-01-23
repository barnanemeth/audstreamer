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
    public let podcastID: String?

    public init(keyword: String? = nil,
                filterFavorites: Bool = false,
                filterDownloads: Bool = false,
                filterWatch: Bool = false,
                podcastID: String? = nil) {
        self.keyword = keyword
        self.filterFavorites = filterFavorites
        self.filterDownloads = filterDownloads
        self.filterWatch = filterWatch
        self.podcastID = podcastID
    }
}

// MARK: - ExpressibleByNilLiteral

extension EpisodeQueryAttributes: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.keyword = nil
        self.filterFavorites = false
        self.filterDownloads = false
        self.filterWatch = false
        self.podcastID = nil
    }
}
