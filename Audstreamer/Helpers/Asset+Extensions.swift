//
//  Asset+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 15..
//

import UIKit

import SFSafeSymbols

extension Asset {
    static func symbol(_ symbol: SFSymbol, scale: UIImage.SymbolScale = .default) -> UIImage {
        let config = UIImage.SymbolConfiguration(scale: scale)
        guard let image = UIImage(systemSymbol: symbol).applyingSymbolConfiguration(config) else {
            return UIImage(systemSymbol: symbol)
        }
        return image
    }
}
