//
//  EpisodeCommon+Extensions.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2023. 06. 04..
//

import Foundation

extension EpisodeCommon {
    init?(from episodeData: Episode) {
        self.id = episodeData.id
        self.title = episodeData.title
        self.duration = episodeData.duration
        self.lastPosition = episodeData.lastPosition ?? -1
    }
}

// MARK: - Downloadable

extension EpisodeCommon: Downloadable {
    var remoteURL: URL { url }
    var userInfo: [String: Any]? { nil }
}

// MARK: - AudioPlayable

extension EpisodeCommon: AudioPlayable {
    var url: URL {
        guard let url = URLHelper.destinationDirectory?.appendingPathComponent(id, conformingTo: .mp3) else {
            preconditionFailure("Cannot get URL")
        }
        return url
    }

    var preferredStartTime: Second? {
        lastPosition > .zero && lastPosition != duration ? Second(lastPosition) : nil
    }
}

// MARK: - NowPlayable

extension EpisodeCommon: NowPlayable {
    var imageURL: URL? { nil }
}
