//
//  FilterAttribute+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import UIKit

import Common
import Domain

internal import SFSafeSymbols

extension FilterAttribute {
    var title: String {
        switch type {
        case .favorites: return L10n.favorites
        case .downloads: return L10n.downloads
        case .watch: return L10n.onWatch
        }
    }

    var systemImage: String {
        switch type {
        case .favorites: SFSymbol.heart.rawValue
        case .downloads: SFSymbol.arrowDownCircle.rawValue
        case .watch: SFSymbol.applewatch.rawValue
        }
    }
}
