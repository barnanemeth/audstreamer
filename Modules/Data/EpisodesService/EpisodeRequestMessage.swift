//
//  EpisodeRequestMessage.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 13..
//

import Foundation

struct EpisodeRequestMessage: WatchConnectivityEpisodeBasedMessage {

    // MARK: Properties

    static var messageKey: String { WatchConnectivityMessageKey.episodeRequest.rawValue }

    let episodeID: String

    var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.episodeIDKey: episodeID
            ] as [String: Any]
        ]
    }

    // MARK: Init

    init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let episodeID = messageDictionary[Self.episodeIDKey] as? String else { return nil }
        self.episodeID = episodeID
    }

    init(episodeID: String) {
        self.episodeID = episodeID
    }
}
