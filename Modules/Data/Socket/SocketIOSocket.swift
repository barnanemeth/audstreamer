//
//  SocketIOSocket.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 21..
//

import UIKit
import Combine

import Common
import Domain

import SocketIO

final class SocketIOSocket {

    // MARK: Constants

    private enum Constant {
        static let deviceNameHeaderKey = "X-Device-Name"
        static let deviceIDHeaderKey = "X-Device-ID"
        static let deviceTypeHeaderKey = "X-Device-Type"
        static let authorizationHeaderKey = "Authorization"
        static let authorizationHeaderFormat = "Bearer %@"
        static let connectionEmitDelay: TimeInterval = 0.5
        static let reconnectAttempts = 10
    }

    // MARK: Dependencies

    @Injected private var secureStore: SecureStore

    // MARK: Private properties

    private lazy var manager: SocketManager = {
        SocketManager(socketURL: AppSettings.socketBaseURL, config: configuration)
    }()
    private var client: SocketIOClient { manager.defaultSocket }
    private var settedCallbacks = Set<SocketEvent>()
    private var headers: [String: String] {
        var headers: [String: String] = [
            Constant.deviceNameHeaderKey: DeviceHelper.deviceName,
            Constant.deviceIDHeaderKey: DeviceHelper.deviceID,
            Constant.deviceTypeHeaderKey: DeviceHelper.deviceModel
        ]
        if let authorizationToken = try? secureStore.getToken() {
            headers[Constant.authorizationHeaderKey] = String(
                format: Constant.authorizationHeaderFormat, authorizationToken
            )
        }
        return headers
    }
    private var configuration: SocketIOClientConfiguration {
        // swiftlint:disable vertical_parameter_alignment_on_call
        SocketIOClientConfiguration(arrayLiteral:
                .path(AppSettings.socketPath),
                .log(false),
                .compress,
                .extraHeaders(headers),
                .version(.three),
                .reconnectAttempts(Constant.reconnectAttempts)
        )
        // swiftlint:enable vertical_parameter_alignment_on_call
    }

    private lazy var currentEpisodeCallback: NormalCallback = { [unowned self] data, _ in
        guard let currentEpisodeSocketData = CurrentEpisodeSocketData(data: data) else { return }
        self.currentEpisodeSubject.send(currentEpisodeSocketData)
    }
    private lazy var playbackStateCallback: NormalCallback = { [unowned self] data, _ in
        guard let playbackStateSocketData = PlaybackStateSocketData(data: data) else { return }
        self.playbackStateSubject.send(playbackStateSocketData)
    }
    private lazy var deviceListCallback: NormalCallback = { [unowned self] data, _ in
        self.deviceListSubject.send(Device.devicesFromData(data))
    }
    private lazy var activeDeviceCallback: NormalCallback = { [unowned self] data, _ in
        guard let deviceID = data.first as? String else { return }
        self.activeDeviceSubject.send(deviceID)
    }
    private lazy var playbackCommandCallback: NormalCallback = { [unowned self] data, _ in
        guard let playbackCommand = PlaybackCommand(data: data) else { return }
        self.playbackCommandSubject.send(playbackCommand)
    }

    private let statusSubject = CurrentValueSubject<SocketStatus, Error>(.disconnected)
    private let currentEpisodeSubject = PassthroughSubject<CurrentEpisodeSocketData, Error>()
    private let playbackStateSubject = PassthroughSubject<PlaybackStateSocketData, Error>()
    private let deviceListSubject = CurrentValueSubject<[Device], Error>([])
    private let activeDeviceSubject = CurrentValueSubject<String?, Error>(nil)
    private let playbackCommandSubject = PassthroughSubject<PlaybackCommand, Error>()

    private var isAuthenticationTokenExists: Bool {
        (try? secureStore.getToken()) != nil
    }

    // MARK: Init

    init() {
        setupConnectionCallbacks()
    }
}

// MARK: - Socket

extension SocketIOSocket: Socket {
    func connect() -> AnyPublisher<Void, Error> {
        guard client.status != .connected else { return Just.void() }
        guard isAuthenticationTokenExists else {
            return Just(statusSubject.send(.disconnected)).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        return Promise<Void, Error> { [unowned self] promise in
            self.client.on(clientEvent: .connect) { _, _ in promise(.success(())) }
            self.client.on(clientEvent: .error) { data, _ in
                promise(.failure(SocketError.connectionError(data.first as? String)))
            }

            self.manager.setConfigs(configuration)
            self.client.connect()
        }
        .handleEvents(receiveCompletion: { [unowned self] _ in self.removeHandlers(for: .connect, .error) })
        .eraseToAnyPublisher()
    }

    func disconnect() -> AnyPublisher<Void, Error> {
        guard client.status == .connected || client.status == .connecting else { return Just.void() }
        return Just(self.manager.disconnect()).setFailureType(to: Error.self).eraseToAnyPublisher()

//        return Promise<Void, Error> { [unowned self] promise in
//            self.client.on(clientEvent: .disconnect) { _, _ in promise(.success(())) }
//
//            self.manager.disconnect()
//        }
//        .handleEvents(receiveCompletion: { [unowned self] _ in self.removeHandlers(for: .disconnect) })
//        .eraseToAnyPublisher()
    }

    func getStatus() -> AnyPublisher<SocketStatus, Error> {
        statusSubject.eraseToAnyPublisher()
    }

    func getCurrentEpisode() -> AnyPublisher<CurrentEpisodeSocketData, Error> {
        defer { registerCallbackHandler(for: .currentEpisode, callbackHandler: currentEpisodeCallback) }
        return currentEpisodeSubject.eraseToAnyPublisher()
    }

    func getPlaybackState() -> AnyPublisher<PlaybackStateSocketData, Error> {
        defer { registerCallbackHandler(for: .playbackState, callbackHandler: playbackStateCallback) }
        return playbackStateSubject.eraseToAnyPublisher()
    }

    func getDeviceList() -> AnyPublisher<[Device], Error> {
        defer { registerCallbackHandler(for: .deviceListUpdate, callbackHandler: deviceListCallback) }
        return deviceListSubject.eraseToAnyPublisher()
    }

    func getActiveDevice() -> AnyPublisher<String?, Error> {
        defer { registerCallbackHandler(for: .activeDevice, callbackHandler: activeDeviceCallback) }
        return activeDeviceSubject.eraseToAnyPublisher()
    }

    func getPlaybackCommand() -> AnyPublisher<PlaybackCommand, Error> {
        defer { registerCallbackHandler(for: .playbackCommand, callbackHandler: playbackCommandCallback) }
        return playbackCommandSubject.eraseToAnyPublisher()
    }

    func sendCurrentEpisode(_ currentEpisode: CurrentEpisodeSocketData) -> AnyPublisher<Void, Error> {
        guard client.status == .connected else { return Just.void() }
        return Just(client.emit(SocketEvent.currentEpisode.rawValue, currentEpisode.data))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func sendPlaybackState(_ playbackState: PlaybackStateSocketData) -> AnyPublisher<Void, Error> {
        guard client.status == .connected else { return Just.void() }
        return Just(client.emit(SocketEvent.playbackState.rawValue, playbackState.data))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func sendActiveDevice(_ activeDeviceID: String) -> AnyPublisher<Void, Error> {
        guard client.status == .connected else { return Just.void() }
        return Just(client.emit(SocketEvent.activeDevice.rawValue, activeDeviceID))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func sendPlaybackCommand(_ playbackCommand: PlaybackCommand) -> AnyPublisher<Void, Error> {
        guard client.status == .connected else { return Just.void() }
        return Just(client.emit(SocketEvent.playbackCommand.rawValue, playbackCommand.data))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension SocketIOSocket {
    private func setupConnectionCallbacks() {
        client.on(clientEvent: .statusChange) { [unowned self] data, _ in
            guard let status = data.first as? SocketIOStatus else { return }
            switch status {
            case .connected:
                self.statusSubject.send(.connected)
            case .disconnected, .notConnected:
                self.statusSubject.send(.disconnected)
                self.deviceListSubject.send([])
                self.activeDeviceSubject.send(DeviceHelper.deviceID)
            case .connecting:
                self.statusSubject.send(.pending)
            }
        }
    }

    private func registerCallbackHandler(for event: SocketEvent, callbackHandler: @escaping NormalCallback) {
        guard !settedCallbacks.contains(event) else { return }
        client.on(event.rawValue, callback: callbackHandler)
        settedCallbacks.insert(event)
    }

    private func removeHandlers(for events: SocketClientEvent...) {
        events.forEach { client.off(clientEvent: $0) }
    }
}
