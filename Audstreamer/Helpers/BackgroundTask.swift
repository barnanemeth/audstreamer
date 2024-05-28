//
//  BackgroundTask.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 26..
//

import UIKit

public class BackgroundTask {

    // MARK: Private properties

    private let id: String
    private var bgTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private var name: String { id }

    // MARK: Init

    public init(id: String) {
        self.id = id
    }

    // MARK: Public methods

    public func begin(expirationHandler: (() -> Void)? = nil) {
        let handler: (() -> Void) = { [weak self] in
            expirationHandler?()
            self?.end()
        }
        bgTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: name, expirationHandler: handler)
        assert(bgTaskIdentifier != .invalid)
    }
    public func end() {
        if bgTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(bgTaskIdentifier)
        }
        bgTaskIdentifier = .invalid
    }
}

// MARK: - Equatable

extension BackgroundTask: Equatable {
    public static func == (lhs: BackgroundTask, rhs: BackgroundTask) -> Bool {
        return lhs.id == rhs.id
    }
}
