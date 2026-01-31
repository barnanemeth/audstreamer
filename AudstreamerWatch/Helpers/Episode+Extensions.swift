//
//  Episode+Extensions.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2026. 01. 09..
//

import Foundation

import Domain

// MARK: - Decodables

extension Episode: @retroactive Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let publishDate = try container.decode(Date.self, forKey: .publishDate)
        let duration = try container.decode(Int.self, forKey: .duration)
        let lastPosition = try container.decode(Int.self, forKey: .lastPosition)
        let mediaURL = WatchURLHelper.getURLForEpisode(id)! // swiftlint:disable:this force_unwrapping
        let podcastTitle = try container.decode(String.self, forKey: .podcastTitle)

        self.init(
            id: id,
            title: title,
            publishDate: publishDate,
            mediaURL: mediaURL,
            podcastTitle: podcastTitle,
            duration: duration,
            lastPosition: lastPosition,
            isDownloaded: false,
            isOnWatch: false
        )
    }
}

// MARK: - Encodable

extension Episode: @retroactive Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(publishDate, forKey: .publishDate)
        try container.encode(duration, forKey: .duration)
        try container.encode(lastPosition, forKey: .lastPosition)
        try container.encode(podcastTitle, forKey: .podcastTitle)
    }
}

extension Episode {
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary[CodingKeys.id.rawValue] as? String,
              let title = dictionary[CodingKeys.title.rawValue] as? String,
              let publishDate = dictionary[CodingKeys.publishDate.rawValue] as? Date,
              let mediaURL = WatchURLHelper.getURLForEpisode(id),
              let podcastTitle = dictionary[CodingKeys.podcastTitle.rawValue] as? String,
              let duration = dictionary[CodingKeys.duration.rawValue] as? Int,
              let lastPosition = dictionary[CodingKeys.lastPosition.rawValue] as? Int else {
                  return nil
              }
        self.init(
            id: id,
            title: title,
            publishDate: publishDate,
            mediaURL: mediaURL,
            podcastTitle: podcastTitle,
            duration: duration,
            lastPosition: lastPosition
        )
    }
}
