//
//  DialogAction.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import Foundation

public struct DialogAction {

    // MARK: Inner types

    public enum `Type` {
        case normal
        case cancel
        case destructive
    }

    // MARK: Properties

    public let title: String
    public let type: `Type`
    public let action: (() -> Void)?

    // MARK: Private properties

    private let id = UUID()

    // MARK: Init

    public init(title: String, type: Type = .normal, action: (() -> Void)? = nil) {
        self.title = title
        self.type = type
        self.action = action
    }
}

// MARK: - Hashable & Equatable

extension DialogAction: Hashable, Equatable {
    public static func == (lhs: DialogAction, rhs: DialogAction) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
