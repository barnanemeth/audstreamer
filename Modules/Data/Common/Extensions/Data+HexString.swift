//
//  Data+HexString.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 03. 10..
//

import Foundation

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
