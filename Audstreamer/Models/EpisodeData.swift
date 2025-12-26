//
//  EpisodeData.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import Foundation

import RealmSwift

final class EpisodeData: Object, Decodable {

    // MARK: Properties

    @objc dynamic var id: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var publishDate = Date()
    @objc dynamic var descriptionText: String = ""
    @objc dynamic var mediaURL: String?
    @objc dynamic var image: String?
    @objc dynamic var thumbnail: String?
    @objc dynamic var link: String?
    @objc dynamic var maybeAudioInvalid = false
    @objc dynamic var duration: Int = 0

    @objc dynamic var isFavourite = false
    @objc dynamic var lastPosition: Int = -1
    @objc dynamic var lastPlayed: Date?
    @objc dynamic var isDownloaded = false
    @objc dynamic var numberOfPlays = 0
    @objc dynamic var isOnWatch = false
}

// MARK: - Realm overrides

extension EpisodeData {
    override class func primaryKey() -> String? {
        "id"
    }
}
