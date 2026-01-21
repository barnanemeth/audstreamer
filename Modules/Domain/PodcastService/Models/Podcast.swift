//
//  Podcast.swift
//  Domain
//
//  Created by Barna Nemeth on 2026. 01. 20..
//

import Foundation

public struct Podcast: Identifiable, Hashable, Equatable {

    // MARK: Properties

    public let id: String
    public let title: String
    public let description: String?
    public let author: String?
    public let isExplicit: Bool?
    public let rssFeedURL: URL
    public let imageURL: URL?
    public let linkURL: URL?
    public let isPrivate: Bool

    // MARK: Init

    public init(id: String,
         title: String,
         description: String?,
         author: String?,
         isExplicit: Bool?,
         rssFeedURL: URL,
         imageURL: URL?,
         linkURL: URL?,
         isPrivate: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.author = author
        self.isExplicit = isExplicit
        self.rssFeedURL = rssFeedURL
        self.imageURL = imageURL
        self.linkURL = linkURL
        self.isPrivate = isPrivate
    }
}
