//
//  WatchConnectivityMessage.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 05..
//

import Foundation

enum WatchConnectivityMessageKey: String, CaseIterable {
    case lastPlayedDate
    case lastPosition
    case episodeRequest
    case reply

    var modelType: WatchConnectivityMessage.Type {
        switch self {
        case .lastPlayedDate: return LastPlayedDateMessage.self
        case .lastPosition: return LastPositionMessage.self
        case .episodeRequest: return EpisodeRequestMessage.self
        case .reply: return ReplyMessage.self
        }
    }
}

protocol WatchConnectivityMessage {
    static var messageKey: String { get }
    var asUserInfo: [String: Any] { get }
    init?(from userInfo: [String: Any])
}

protocol WatchConnectivityEpisodeBasedMessage: WatchConnectivityMessage {
    static var episodeIDKey: String { get }
    var episodeID: String { get }
}

extension WatchConnectivityEpisodeBasedMessage {
    static var episodeIDKey: String { "episodeID" }
}
