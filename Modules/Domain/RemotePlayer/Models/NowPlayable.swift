//
//  NowPlayable.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Foundation

public protocol NowPlayable {
    var title: String { get }
    var duration: Int { get }
    var imageURL: URL? { get }
}
