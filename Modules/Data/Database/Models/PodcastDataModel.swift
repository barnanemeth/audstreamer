//
//  PodcastDataModel.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import Foundation
import SwiftData

//@Model
//final class PodcastDataModel {
//
//    // MARK: Properties
//
//    @Attribute(.unique) var id: String
//    var title: String
//    var descriptionText: String?
//    var author: String?
//    var language: String?
//    var rssURL: URL
//    var imageURL: URL?
//    var linkURL: URL?
//
//    @Relationship(deleteRule: .cascade) var episodes = [EpisodeDataModel]()
//
//    // MARK: Init
//
//    init(id: String, title: String,
//        descriptionText: String? = nil,
//         author: String? = nil,
//         language: String? = nil,
//         rssURL: URL,
//         imageURL: URL? = nil,
//         linkURL: URL? = nil,
//         episodes: [EpisodeDataModel] = [EpisodeDataModel]()) {
//        self.id = id
//        self.title = title
//        self.descriptionText = descriptionText
//        self.author = author
//        self.language = language
//        self.rssURL = rssURL
//        self.imageURL = imageURL
//        self.linkURL = linkURL
//        self.episodes = episodes
//    }
//}
