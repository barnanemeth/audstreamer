//
//  BadgeButton.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 20..
//

import Foundation

class BadgeButton: SYBadgeButton {
    private var targetSetForAction = false
    var action: CocoaAction? {
        didSet {
            guard action != nil else {
                removeTarget(self, action: #selector(tapGestureSelector), for: .touchUpInside)
                targetSetForAction = false
                return
            }

            guard !targetSetForAction else { return }
            addTarget(self, action: #selector(tapGestureSelector), for: .touchUpInside)
            targetSetForAction = true
        }
    }
}

// MARK: - Private helpers

extension BadgeButton {
    @objc private func tapGestureSelector() {
        action?.execute()
    }
}
