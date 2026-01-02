//
//  EpisodeCommon.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 04..
//

import Foundation

import Common

import UniformTypeIdentifiers

public struct EpisodeCommon: Codable, Hashable, Equatable {

    // MARK: Constants

    private enum Keys: String {
        case id
        case title
        case duration
        case lastPosition
    }

    // MARK: Properties

    public let id: String
    public let title: String
    public let duration: Int
    public let lastPosition: Int
    public var isDownloaded = false

    public var asDictionary: [String: Any] {
        [
            Keys.id.rawValue: id,
            Keys.title.rawValue: title,
            Keys.duration.rawValue: duration,
            Keys.lastPosition.rawValue: lastPosition
        ]
    }

    // MARK: Init

    public init?(from dictionary: [String: Any]) {
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

    public init?(from episodeData: Episode) {
        self.id = episodeData.id
        self.title = episodeData.title
        self.duration = episodeData.duration
        self.lastPosition = episodeData.lastPosition ?? -1
    }
}

// MARK: - Downloadable

extension EpisodeCommon: Downloadable {
    public var remoteURL: URL { url }
    public var userInfo: [String: Any]? { nil }
}

// MARK: - AudioPlayable

extension EpisodeCommon: AudioPlayable {
    public var url: URL {
        guard let url = URLHelper.destinationDirectory?.appendingPathComponent(id, conformingTo: .mp3) else {
            preconditionFailure("Cannot get URL")
        }
        return url
    }

    public var preferredStartTime: Second? {
        lastPosition > .zero && lastPosition != duration ? Second(lastPosition) : nil
    }
}

// MARK: - NowPlayable

extension EpisodeCommon: NowPlayable {
    public var imageURL: URL? { nil }
}
