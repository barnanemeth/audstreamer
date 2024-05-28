//
//  AppleAuthorizationButton.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation
import AuthenticationServices

final class AppleAuthorizationButton: ASAuthorizationAppleIDButton {
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

extension AppleAuthorizationButton {
    @objc private func tapGestureSelector() {
        action?.execute()
    }
}