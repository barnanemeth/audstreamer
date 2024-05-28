//
//  String+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 04. 09..
//

import Foundation

extension String {
    var trimmedHTMLTags: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
