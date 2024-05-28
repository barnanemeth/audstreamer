//
//  EpisodeCommon.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 04..
//

import Foundation

struct EpisodeCommon: Codable {

    // MARK: Constants

    private enum Keys: String {
        case id
        case title
        case duration
        case lastPosition
    }

    // MARK: Properties

    let id: String
    let title: String
    let duration: Int
    let lastPosition: Int
    var isDownloaded = false

    var asDictionary: [String: Any] {
        [
            Keys.id.rawValue: id,
            Keys.title.rawValue: title,
            Keys.duration.rawValue: duration,
            Keys.lastPosition.rawValue: lastPosition
        ]
    }

    // MARK: Init

    init?(from dictionary: [String: Any]) {
        guard let id = dictionary[Keys.id.rawValue] as? String,
              let title = dictionary[Keys.title.rawValue] as? String,
              let duration = dictionary[Keys.duration.rawValue] as? Int,
              let lastPosition = dictionary[Keys.lastPosition.rawValue] as? Int else {
                  return nil
              }
        self.id = id
        self.title = title
        self.duration = duration
        self.lastPosition = lastPosition
    }
}

// MARK: - Hashable & Equatable

extension EpisodeCommon: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (_ lhs: EpisodeCommon, _ rhs: EpisodeCommon) -> Bool {
        lhs.id == rhs.id
    }
}
