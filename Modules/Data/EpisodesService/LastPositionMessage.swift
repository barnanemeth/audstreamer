//
//  LastPositionMessage.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 05..
//

import Foundation

struct LastPositionMessage: WatchConnectivityEpisodeBasedMessage {

    // MARK: Constants

    private enum Constant {
        static let positionKey = "position"
    }

    // MARK: Properties

    static var messageKey: String { WatchConnectivityMessageKey.lastPosition.rawValue }

    let episodeID: String
    let position: Int

    var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.episodeIDKey: episodeID,
                Constant.positionKey: position
            ] as [String: Any]
        ]
    }

    // MARK: Init

    init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let episodeID = messageDictionary[Self.episodeIDKey] as? String,
              let position = messageDictionary[Constant.positionKey] as? Int else { return nil }
        self.episodeID = episodeID
        self.position = position
    }

    init(episodeID: String, position: Int) {
        self.episodeID = episodeID
        self.position = position
    }
}
