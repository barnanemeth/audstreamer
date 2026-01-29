//
//  Environment+Seleciton.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 23..
//

import SwiftUI

public struct SelectionEnvironmentKey: EnvironmentKey {
    public static let defaultValue = false
}

extension EnvironmentValues {
    public var isSelected: Bool {
        get { self[SelectionEnvironmentKey.self] }
        set { self[SelectionEnvironmentKey.self] = newValue }
    }
}
