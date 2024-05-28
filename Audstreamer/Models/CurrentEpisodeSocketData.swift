//
//  CurrentEpisodeSocketData.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 03. 04..
//

import Foundation

struct CurrentEpisodeSocketData {

    // MARK: Properties

    let episodeID: String
    let playImmediately: Bool

    var data: [Any] { [episodeID, playImmediately] }

    // MARK: Init

    init?(data: [Any]) {
        guard let array = data.first as? NSArray, array.count == 2 else { return nil }
        guard let episodeID = array[0] as? String, let playImmediately = array[1] as? Bool else { return nil }
        self.episodeID = episodeID
        self.playImmediately = playImmediately
    }

    init(episodeID: String, playImmediately: Bool) {
        self.episodeID = episodeID
        self.playImmediately = playImmediately
    }
}
