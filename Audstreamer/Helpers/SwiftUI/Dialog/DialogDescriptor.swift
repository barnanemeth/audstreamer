//
//  DialogDescriptor.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import Foundation

struct DialogDescriptor: Equatable {

    // MARK: Inner types

    enum `Type` {
        case alert
        case confirmationDialog
    }

    // MARK: Properties

    let title: String
    let message: String?
    let type: `Type`
    let actions: [DialogAction]?

    // MARK: Init

    init(title: String, message: String? = nil, type: Self.`Type` = .alert, actions: [DialogAction]? = nil) {
        self.title = title
        self.message = message
        self.actions = actions
        self.type = type
    }
}
