//
//  CurrentEpisodeSocketData.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 03. 04..
//

import Foundation

public struct CurrentEpisodeSocketData {

    // MARK: Properties

    public let episodeID: String
    public let playImmediately: Bool

    public var data: [Any] { [episodeID, playImmediately] }

    // MARK: Init

    public init?(data: [Any]) {
        guard let array = data.first as? NSArray, array.count == 2 else { return nil }
        guard let episodeID = array[0] as? String, let playImmediately = array[1] as? Bool else { return nil }
        self.episodeID = episodeID
        self.playImmediately = playImmediately
    }

    public init(episodeID: String, playImmediately: Bool) {
        self.episodeID = episodeID
        self.playImmediately = playImmediately
    }
}
