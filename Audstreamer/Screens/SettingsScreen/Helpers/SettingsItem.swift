//
//  SettingsItem.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 16..
//

import Foundation

enum SettingsItem: Hashable, Equatable {

    // MARK: Inner types

    enum SocketActionType {
        case connect
        case disconnect
    }

    enum AccountActionType {
        case login
        case logout
    }

    // MARK: Cases

    case storageInfo(downloadSize: Int)
    case storageAction
    case socketInfo(status: SocketStatus)
    case socketAction(type: SocketActionType)
    case accountAction(type: AccountActionType)

    // MARK: Properties

    var isAction: Bool {
        switch self {
        case .storageAction, .socketAction, .accountAction: return true
        default: return false
        }
    }
}
