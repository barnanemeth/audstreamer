//
//  Socket.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 21..
//

import Combine

protocol Socket {
    func connect() -> AnyPublisher<Void, Error>
    func disconnect() -> AnyPublisher<Void, Error>
    func getStatus() -> AnyPublisher<SocketStatus, Error>
    func getCurrentEpisode() -> AnyPublisher<CurrentEpisodeSocketData, Error>
    func getPlaybackState() -> AnyPublisher<PlaybackStateSocketData, Error>
    func getDeviceList() -> AnyPublisher<[Device], Error>
    func getActiveDevice() -> AnyPublisher<String?, Error>
    func getPlaybackCommand() -> AnyPublisher<PlaybackCommand, Error>
    func sendCurrentEpisode(_ currentEpisode: CurrentEpisodeSocketData) -> AnyPublisher<Void, Error>
    func sendPlaybackState(_ playbackState: PlaybackStateSocketData) -> AnyPublisher<Void, Error>
    func sendActiveDevice(_ activeDevice: String) -> AnyPublisher<Void, Error>
    func sendPlaybackCommand(_ playbackCommand: PlaybackCommand) -> AnyPublisher<Void, Error>
}

enum SocketEvent: String {
    case currentEpisode = "current_episode"
    case playbackState = "playback_state"
    case deviceListUpdate = "device_list_update"
    case activeDevice = "active_device"
    case playbackCommand = "playback_command"
}

enum SocketStatus {
    case disconnected
    case connected
    case pending
}

enum SocketError: Error {
    case connectionError(String?)
    case disconnected
}
