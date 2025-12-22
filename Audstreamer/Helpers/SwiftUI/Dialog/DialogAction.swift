//
//  DialogAction.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import Foundation

struct DialogAction {

    // MARK: Inner types

    enum `Type` {
        case normal
        case cancel
        case destructive
    }

    // MARK: Properties

    let title: String
    let type: `Type`
    let action: (() -> Void)?

    // MARK: Private properties

    private let id = UUID()

    // MARK: Init

    init(title: String, type: Type = .normal, action: (() -> Void)? = nil) {
        self.title = title
        self.type = type
        self.action = action
    }
}

// MARK: - Equatable

extension DialogAction: Equatable {
    static func == (lhs: DialogAction, rhs: DialogAction) -> Bool {
        lhs.id == rhs.id
    }
}
