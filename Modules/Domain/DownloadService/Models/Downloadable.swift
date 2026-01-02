//
//  Downloadable.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Foundation

import Common

import UniformTypeIdentifiers

public protocol Downloadable {
    var id: String { get }
    var title: String { get }
    var remoteURL: URL { get }
    var userInfo: [String: Any]? { get }
}

extension Downloadable {
    public var possibleLocalURL: URL? {
        URLHelper.destinationDirectory?.appendingPathComponent(id, conformingTo: .mp3)
    }

    public var isSilentDownloading: Bool {
        guard let isSilentDownloading = userInfo?[UserInfoKeys.isSilentDownloading] as? Bool else { return false }
        return isSilentDownloading
    }
}
