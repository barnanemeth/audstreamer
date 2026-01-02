//
//  DialogDescriptor.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import Foundation

public struct DialogDescriptor: Equatable {

    // MARK: Inner types

    public enum `Type` {
        case alert
        case confirmationDialog
    }

    // MARK: Properties

    public let title: String
    public let message: String?
    public let type: `Type`
    public let actions: [DialogAction]?

    // MARK: Init

    public init(title: String, message: String? = nil, type: Self.`Type` = .alert, actions: [DialogAction]? = nil) {
        self.title = title
        self.message = message
        self.actions = actions
        self.type = type
    }
}
