//
//  AudioPlayable.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Foundation

public protocol AudioPlayable {
    var id: String { get }
    var url: URL { get }
    var preferredStartTime: Second? { get }
}
