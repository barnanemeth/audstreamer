//
//  EpisodeCommon+Extensions.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 02/11/2023.
//

import Foundation

// MARK: - Downloadable

//extension EpisodeCommon: Downloadable {
//    var remoteURL: URL {
//        fatalError("Cannot get remoteURL in this target")
//    }
//
//    var userInfo: [String: Any]? {
//        nil
//    }
//}

// MARK: - AudioPlayable

//extension EpisodeCommon: AudioPlayable {
//    var url: URL {
//        guard let url = WatchURLHelper.getURLForEpisode(id) else { fatalError("Cant get URL for episdoe") }
//        return url
//    }
//
//    var preferredStartTime: Second? {
//        lastPosition > .zero && lastPosition != duration ? Second(lastPosition) : nil
//    }
//}

// MARK: - NowPlayable

//extension EpisodeCommon: NowPlayable {
//    var imageURL: URL? { nil }
//}
