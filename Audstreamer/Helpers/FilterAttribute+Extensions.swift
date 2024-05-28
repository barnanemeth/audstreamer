//
//  FilterAttribute+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import UIKit

extension FilterAttribute {
    var title: String {
        switch type {
        case .favorites: return L10n.favorites
        case .downloads: return L10n.downloads
        case .watch: return L10n.onWatch
        }
    }

    var image: UIImage? {
        switch type {
        case .favorites: return Asset.symbol(.heart)
        case .downloads: return Asset.symbol(.arrowDownCircle)
        case .watch: return Asset.symbol(.applewatch)
        }
    }
}
