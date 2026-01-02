//
//  ReplyMessage.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 13..
//

import Foundation

struct ReplyMessage: WatchConnectivityMessage {

    // MARK: Enums

    // MARK: Constants

    private enum Constant {
        static let statusKey = "status"
    }

    enum Status: String {
        case success
        case failed
    }

    // MARK: Properties

    static var messageKey: String { WatchConnectivityMessageKey.reply.rawValue }

    let status: Status

    var asUserInfo: [String: Any] {
        [
            Self.messageKey: [
                Self.Constant.statusKey: status.rawValue
            ] as [String: Any]
        ]
    }

    init?(from userInfo: [String: Any]) {
        guard let messageDictionary = userInfo[Self.messageKey] as? [String: Any],
              let statusString = messageDictionary[Constant.statusKey] as? String,
              let status = Status(rawValue: statusString) else { return nil }
        self.status = status
    }

    init(status: Status) {
        self.status = status
    }
}
