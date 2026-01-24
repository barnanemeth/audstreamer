//
//  Episode+Extensions.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 09..
//

import Foundation

import Domain

extension Episode {
    var asDictionary: [String: Any] {
        [
            CodingKeys.id.rawValue: id,
            CodingKeys.title.rawValue: title,
            CodingKeys.publishDate.rawValue: publishDate,
            CodingKeys.duration.rawValue: duration,
            CodingKeys.lastPosition.rawValue: lastPosition ?? -1,
            CodingKeys.podcastTitle.rawValue: podcastTitle
        ]
    }
}
