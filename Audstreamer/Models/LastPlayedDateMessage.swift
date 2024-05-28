//
//  LastPlayedDateMessage.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 05..
//

import Foundation

struct LastPlayedDateMessage: WatchConnectivityEpisodeBasedMessage {

    // MARK: Constants

    private enum Constant {
        static let dateKey = "date"
    }

    // MARK: Properties

    static var messageKey: String { WatchConnectivityMessageKey.lastPlayedDate.rawValue }

    let episodeID: String
    let date: Date

    var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.episodeIDKey: episodeID,
                Constant.dateKey: date
            ] as [String: Any]
        ]
    }

    // MARK: Init

    init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let episodeID = messageDictionary[Self.episodeIDKey] as? String,
              let date = messageDictionary[Constant.dateKey] as? Date else { return nil }
        self.episodeID = episodeID
        self.date = date
    }

    init(episodeID: String, date: Date) {
        self.episodeID = episodeID
        self.date = date
    }
}
