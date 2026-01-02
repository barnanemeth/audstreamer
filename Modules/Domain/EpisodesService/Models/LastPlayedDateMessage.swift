//
//  LastPlayedDateMessage.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 05..
//

import Foundation

public struct LastPlayedDateMessage: WatchConnectivityEpisodeBasedMessage {

    // MARK: Constants

    private enum Constant {
        static let dateKey = "date"
    }

    // MARK: Properties

    public static var messageKey: String { WatchConnectivityMessageKey.lastPlayedDate.rawValue }

    public let episodeID: String
    public let date: Date

    public var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.episodeIDKey: episodeID,
                Constant.dateKey: date
            ] as [String: Any]
        ]
    }

    // MARK: Init

    public init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let episodeID = messageDictionary[Self.episodeIDKey] as? String,
              let date = messageDictionary[Constant.dateKey] as? Date else { return nil }
        self.episodeID = episodeID
        self.date = date
    }

    public init(episodeID: String, date: Date) {
        self.episodeID = episodeID
        self.date = date
    }
}
