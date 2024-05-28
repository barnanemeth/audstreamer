//
//  FloatingPoint+Extension.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 12..
//

import Foundation

extension FloatingPoint {
    func isNearlyEqual(to value: Self) -> Bool {
        let absA = abs(self)
        let absB = abs(value)
        let diff = abs(self - value)

        if self == value { // shortcut, handles infinities
            return true
        } else if self == .zero || value == .zero || (absA + absB) < Self.leastNormalMagnitude {
            // a or b is zero or both are extremely close to it
            // relative error is less meaningful here
            return diff < Self.ulpOfOne * Self.leastNormalMagnitude
        } else { // use relative error
            return diff / min((absA + absB), Self.greatestFiniteMagnitude) < .ulpOfOne
        }
    }
}
