//
//  URL+ExpressibleByStringLiteral.swift
//  Common
//
//  Created by Barna Nemeth on 2026. 01. 19..
//

import Foundation

extension URL: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}
extension URL: @retroactive ExpressibleByUnicodeScalarLiteral {}
extension URL: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(string: value)!
    }
}
