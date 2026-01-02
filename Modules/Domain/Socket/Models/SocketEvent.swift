//
//  SocketEvent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

public enum SocketEvent: String {
    case currentEpisode = "current_episode"
    case playbackState = "playback_state"
    case deviceListUpdate = "device_list_update"
    case activeDevice = "active_device"
    case playbackCommand = "playback_command"
}
