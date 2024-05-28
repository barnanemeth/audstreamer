//
//  TapGestureRecognizer.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 19..
//

import UIKit

public final class TapGestureRecognizer: UITapGestureRecognizer {
    private var targetSetForAction = false
    public var action: CocoaAction? {
        didSet {
            guard action != nil else {
                removeTarget(self, action: #selector(tapGestureSelector))
                targetSetForAction = false
                return
            }

            guard !targetSetForAction else { return }
            addTarget(self, action: #selector(tapGestureSelector))
            targetSetForAction = true
        }
    }
}

// MARK: - Private helpers

extension TapGestureRecognizer {
    @objc private func tapGestureSelector() {
        action?.execute()
    }
}
