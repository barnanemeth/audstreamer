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

    // MARK: Coding keys

    enum CodingKeys: String, CodingKey {
        case thumbnail
        case publishDate = "pub_date_ms"
        case id
        case title
        case image
        case link
        case descriptionText = "description"
        case mediaURL = "audio"
        case maybeAudioInvalid = "maybe_audio_invalid"
        case duration = "audio_length_sec"
    }

    // MARK: Init

    convenience init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)

        thumbnail = try container.decode(String?.self, forKey: .thumbnail)
        publishDate = try container.decode(Date.self, forKey: .publishDate)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        image = try container.decode(String?.self, forKey: .image)
        link = try container.decode(String?.self, forKey: .link)
        descriptionText = try container.decode(String.self, forKey: .descriptionText)
        maybeAudioInvalid = try container.decode(Bool.self, forKey: .maybeAudioInvalid)
        mediaURL = try container.decode(String?.self, forKey: .mediaURL)
        duration = (try? container.decode(Int?.self, forKey: .duration)) ?? 0
    }
}

// MARK: - Realm overrides

extension EpisodeData {
    override class func primaryKey() -> String? {
        "id"
    }
}

// MARK: - AudioPlayable

extension EpisodeData: AudioPlayable {
    var url: URL {
        if isDownloaded, let localURL = possibleLocalURL {
            return localURL
        } else if let mediaURLString = mediaURL, let mediaURL = URL(string: mediaURLString) {
            return mediaURL
        }
        preconditionFailure("Cannot get mediaURL")
    }
    var preferredStartTime: Second? {
        lastPosition > .zero && lastPosition != duration ? Second(lastPosition) : nil
    }
}

// MARK: - NowPlayable

extension EpisodeData: NowPlayable {
    var imageURL: URL? {
        guard let imageURLString = image?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: imageURLString)
    }
}

// MARK: - Downloadable

extension EpisodeData: Downloadable {
    var remoteURL: URL {
        guard let urlString = mediaURL, let url = URL(string: urlString) else {
            preconditionFailure("Cannot get URL")
        }
        return url
    }

    var userInfo: [String: Any]? { nil }
}
