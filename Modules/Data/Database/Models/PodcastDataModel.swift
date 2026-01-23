//
//  PodcastDataModel.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import Foundation
import SwiftData

@Model
final class PodcastDataModel {

    // MARK: Properties

    @Attribute(.unique) var id: String
    var title: String
    var descriptionText: String?
    var author: String?
    var language: String?
    var isExplicit: Bool?
    var rssURL: URL
    var imageURL: URL?
    var linkURL: URL?
    var isPrivate: Bool

    @Relationship(deleteRule: .cascade) var episodes: [EpisodeDataModel]

    // MARK: Init

    init(id: String, title: String,
        descriptionText: String?,
         author: String?,
         language: String?,
         isExplicit: Bool?,
         rssURL: URL,
         imageURL: URL?,
         linkURL: URL?,
         isPrivate: Bool,
         episodes: [EpisodeDataModel]) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.author = author
        self.language = language
        self.isExplicit = isExplicit
        self.rssURL = rssURL
        self.imageURL = imageURL
        self.linkURL = linkURL
        self.isPrivate = isPrivate
        self.episodes = episodes
    }
}
