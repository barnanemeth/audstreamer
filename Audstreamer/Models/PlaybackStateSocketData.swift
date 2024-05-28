//
//  PlaybackStateSocketData.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 21..
//

import Foundation

struct PlaybackStateSocketData {

    // MARK: Enums

    enum State: String {
        case playing
        case paused
     }

    // MARK: Properties

    let episodeID: String
    let state: State
    let currentTime: Int

    var data: [Any] { [episodeID, state.rawValue, currentTime] }

    // MARK: Init

    init?(data: [Any]) {
        guard let array = data.first as? NSArray, array.count == 3 else { return nil }
        guard let episodeID = array[0] as? String,
              let stateString = array[1] as? String,
              let state = State(rawValue: stateString),
              let currentTime = array[2] as? Int else { return nil }
        self.episodeID = episodeID
        self.state = state
        self.currentTime = currentTime
    }

    init(episodeID: String, state: State, currentTime: Int) {
        self.episodeID = episodeID
        self.state = state
        self.currentTime = currentTime
    }
}
