//
//  CGSize+Extensions.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 12. 24..
//

import CoreGraphics

extension CGSize {
    static func * (size: CGSize, multiplier: CGFloat) -> CGSize {
        CGSize(width: size.width * multiplier, height: size.height * multiplier)
    }
}
