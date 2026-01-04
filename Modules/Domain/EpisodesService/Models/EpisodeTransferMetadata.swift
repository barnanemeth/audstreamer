//
//  EpisodeTransferMetadat.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 29/10/2023.
//

import Foundation

public struct EpisodeTransferMetadata: WatchConnectivityEpisodeBasedMessage {

    // MARK: Properties

    public let episodeID: String

    public static var messageKey: String {
        "EpisodeMetadata"
    }
    public var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.episodeIDKey: episodeID
            ] as [String: Any]
        ]
    }

    // MARK: Init

    public init(episodeID: String) {
        self.episodeID = episodeID
    }

    public init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let episodeID = messageDictionary[Self.episodeIDKey] as? String else { return nil }
        self.episodeID = episodeID
    }
}
