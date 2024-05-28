//
//  Downloadable+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 02/11/2023.
//

import Foundation

extension Downloadable {
    var possibleLocalURL: URL? {
        URLHelper.destinationDirectory?.appendingPathComponent(id, conformingTo: .mp3)
    }
}
