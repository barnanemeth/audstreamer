//
//  CustomTextFieldSize.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 23..
//

import Foundation

public enum CustomTextFieldSize {
    case large
    case normal
    case small

    var height: CGFloat {
        switch self {
        case .large: 62
        case .normal: 48
        case .small: 36
        }
    }
}
