//
//  Color+Extensions.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 24..
//

import SwiftUI

extension Color {
    public func darken(by percentage: Double) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let factor = CGFloat(1 - percentage)
        return Color(
            red: max(red * factor, 0),
            green: max(green * factor, 0),
            blue: max(blue * factor, 0),
            opacity: Double(alpha)
        )
    }
}
