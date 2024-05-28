//
//  EpisodeTransferMetadat.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 29/10/2023.
//

import Foundation

struct EpisodeTransferMetadata: WatchConnectivityEpisodeBasedMessage {

    // MARK: Properties

    let episodeID: String

    static var messageKey: String {
        "EpisodeMetadata"
    }
    var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.episodeIDKey: episodeID
            ] as [String: Any]
        ]
    }

    // MARK: Init

    init(episodeID: String) {
        self.episodeID = episodeID
    }

    init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let episodeID = messageDictionary[Self.episodeIDKey] as? String else { return nil }
        self.episodeID = episodeID
    }
}
