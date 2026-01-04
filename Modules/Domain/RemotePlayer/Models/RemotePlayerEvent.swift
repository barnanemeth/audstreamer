//
//  RemotePlayerEvent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Foundation

public enum RemotePlayerEvent {
    case play
    case pause
    case skipForward
    case skipBackward
    case changePlaybackPosition(TimeInterval)
    case nextTrack
    case previousTrack
    case seekForward
    case seekBackward
    case likeCommand
    case dislikeCommand
}
