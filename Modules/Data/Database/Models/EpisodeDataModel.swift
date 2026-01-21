//
//  EpisodeDataModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 04..
//

import Foundation
import SwiftData

@Model
final class EpisodeDataModel: Identifiable {

    // MARK: Properties

    @Attribute(.unique) var id: String
    var title: String
    var publishDate: Date
    var descriptionText: String?
    var mediaURL: URL
    var image: URL?
    var thumbnail: URL?
    var link: URL?
    var duration: Int?

    var isFavourite = false
    var lastPosition: Int?
    var lastPlayed: Date?
    var isDownloaded = false
    var numberOfPlays = 0
    var isOnWatch = false

//    @Relationship(inverse: \PodcastDataModel.episodes) var podcast: PodcastDataModel?

    // MARK: Init

    init(id: String,
         title: String,
         publishDate: Date,
         descriptionText: String? = nil,
         mediaURL: URL,
         image: URL? = nil,
         thumbnail: URL? = nil,
         link: URL? = nil,
         duration: Int? = nil,
         isFavourite: Bool = false,
         lastPosition: Int? = nil,
         lastPlayed: Date? = nil,
         isDownloaded: Bool = false,
         numberOfPlays: Int = 0,
         isOnWatch: Bool = false) {
        self.id = id
        self.title = title
        self.publishDate = publishDate
        self.descriptionText = descriptionText
        self.mediaURL = mediaURL
        self.image = image
        self.thumbnail = thumbnail
        self.link = link
        self.duration = duration
        self.isFavourite = isFavourite
        self.lastPosition = lastPosition
        self.lastPlayed = lastPlayed
        self.isDownloaded = isDownloaded
        self.numberOfPlays = numberOfPlays
        self.isOnWatch = isOnWatch
    }
}
