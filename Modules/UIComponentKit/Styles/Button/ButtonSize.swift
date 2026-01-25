//
//  ButtonSize.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 12..
//

import SwiftUI

public enum ButtonSize {
    case normal
    case small

    var font: Font {
        switch self {
        case .normal: .headline
        case .small: .footnote
        }
    }

    var height: CGFloat {
        switch self {
        case .normal: 52
        case .small: 32
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .normal: 12
        case .small: 8
        }
    }

    var borderWidth: CGFloat {
        2
    }

    var iconSize: CGFloat {
        switch self {
        case .normal: 18
        case .small: 14
        }
    }

    var spacing: CGFloat {
        4
    }

    var horizontalPadding: CGFloat {
        16
    }
}
