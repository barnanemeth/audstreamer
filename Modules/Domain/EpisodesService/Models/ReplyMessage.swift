//
//  ReplyMessage.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 13..
//

import Foundation

public struct ReplyMessage: WatchConnectivityMessage {

    // MARK: Enums

    // MARK: Constants

    private enum Constant {
        static let statusKey = "status"
    }

    public enum Status: String {
        case success
        case failed
    }

    // MARK: Properties

    public static var messageKey: String { WatchConnectivityMessageKey.reply.rawValue }

    public let status: Status

    public var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.Constant.statusKey: status.rawValue
            ] as [String: Any]
        ]
    }

    public init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let statusString = messageDictionary[Constant.statusKey] as? String,
              let status = Status(rawValue: statusString) else { return nil }
        self.status = status
    }

    public init(status: Status) {
        self.status = status
    }
}
