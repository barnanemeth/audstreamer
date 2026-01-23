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
    public let language: String?
    public let isExplicit: Bool?
    public let rssFeedURL: URL
    public let imageURL: URL?
    public let linkURL: URL?
    public var isSubscribed: Bool
    public let isPrivate: Bool

    // MARK: Init

    public init(id: String,
         title: String,
         description: String?,
         author: String?,
         language: String?,
         isExplicit: Bool?,
         rssFeedURL: URL,
         imageURL: URL?,
         linkURL: URL?,
         isSubscribed: Bool,
         isPrivate: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.author = author
        self.language = language
        self.isExplicit = isExplicit
        self.rssFeedURL = rssFeedURL
        self.imageURL = imageURL
        self.linkURL = linkURL
        self.isSubscribed = isSubscribed
        self.isPrivate = isPrivate
    }
}
