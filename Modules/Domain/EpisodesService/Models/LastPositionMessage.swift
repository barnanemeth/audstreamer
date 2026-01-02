//
//  LastPositionMessage.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 05..
//

import Foundation

public struct LastPositionMessage: WatchConnectivityEpisodeBasedMessage {

    // MARK: Constants

    private enum Constant {
        static let positionKey = "position"
    }

    // MARK: Properties

    public static var messageKey: String { WatchConnectivityMessageKey.lastPosition.rawValue }

    public let episodeID: String
    public let position: Int

    public var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.episodeIDKey: episodeID,
                Constant.positionKey: position
            ] as [String: Any]
        ]
    }

    // MARK: Init

    public init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let episodeID = messageDictionary[Self.episodeIDKey] as? String,
              let position = messageDictionary[Constant.positionKey] as? Int else { return nil }
        self.episodeID = episodeID
        self.position = position
    }

    public init(episodeID: String, position: Int) {
        self.episodeID = episodeID
        self.position = position
    }
}
