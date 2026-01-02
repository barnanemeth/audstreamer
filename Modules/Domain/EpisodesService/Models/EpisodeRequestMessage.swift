//
//  EpisodeRequestMessage.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 13..
//

import Foundation

public struct EpisodeRequestMessage: WatchConnectivityEpisodeBasedMessage {

    // MARK: Properties

    public static var messageKey: String { WatchConnectivityMessageKey.episodeRequest.rawValue }

    public let episodeID: String

    public var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.episodeIDKey: episodeID
            ] as [String: Any]
        ]
    }

    // MARK: Init

    public init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let episodeID = messageDictionary[Self.episodeIDKey] as? String else { return nil }
        self.episodeID = episodeID
    }

    public init(episodeID: String) {
        self.episodeID = episodeID
    }
}
