//
//  Font+Extensions.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2026. 01. 25..
//

import SwiftUI

extension Font {
    public static let h1 = Font.system(size: 28, weight: .bold)
    public static let h2 = Font.system(size: 24, weight: .bold)
    public static let h3 = Font.system(size: 20, weight: .semibold)
    public static let h4 = Font.system(size: 18, weight: .semibold)
    public static let bodyText = Font.system(size: 16, weight: .regular)
    public static let bodySecondaryText = Font.system(size: 14, weight: .regular)
    public static let button = Font.system(size: 16, weight: .semibold)
    public static let captionText = Font.system(size: 12, weight: .regular)
    public static let label = Font.system(size: 12, weight: .medium)

    public static let h1Rounded = Font.system(size: 28, weight: .bold, design: .rounded)
    public static let h2Rounded = Font.system(size: 24, weight: .bold, design: .rounded)
    public static let h3Rounded = Font.system(size: 20, weight: .semibold, design: .rounded)
    public static let h4Rounded = Font.system(size: 18, weight: .semibold, design: .rounded)
    public static let captionRounded = Font.system(size: 12, weight: .regular, design: .rounded)
    public static let labelRounded = Font.system(size: 12, weight: .medium, design: .rounded)
}
