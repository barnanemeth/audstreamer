//
//  CustomTextFieldContentSize.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 16..
//

import SwiftUI

public enum CustomTextFieldContentSize {
    case normal
    case large

    var font: Font {
        switch self {
        case .normal: .bodySecondaryText
        case .large: .h2
        }
    }
}
