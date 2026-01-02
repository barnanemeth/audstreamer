//
//  WCSessionFileTransfer+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 02/11/2023.
//

import WatchConnectivity

extension WCSessionFileTransfer {
    var id: String? {
        file.fileURL.lastPathComponent.components(separatedBy: ".").first
    }
}
