//
//  NumberFormatterHelper.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 06..
//

import Foundation

enum NumberFormatterHelper {

    // MARK: Public methods

    static func getFormattedContentSize(from bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
