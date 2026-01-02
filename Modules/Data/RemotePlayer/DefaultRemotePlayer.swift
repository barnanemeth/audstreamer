//
//  DefaultRemotePlayer.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 19..
//

import Foundation
import Combine
import MediaPlayer

import Domain

internal import Nuke

final class DefaultRemotePlayer {

    // MARK: Typealiases

    private typealias CommandHandler = ((MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus)

    // MARK: Constants

    private enum Constant {
        static let artistKey = MPMediaItemPropertyArtist
        static let titleKey = MPMediaItemPropertyTitle
        static let artworkKey = MPMediaItemPropertyArtwork
        static let playbackRateKey = MPNowPlayingInfoPropertyPlaybackRate
        static let elapsedPlaybackTimeKey = MPNowPlayingInfoPropertyElapsedPlaybackTime
        static let playbackDurationKey = MPMediaItemPropertyPlaybackDuration
        static let defaultImageSize = CGSize(width: 120, height: 120)
    }

    // MARK: Private properties

    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let eventsSubject = PassthroughSubject<RemotePlayerEvent, Error>()
    private var appTitle: Any? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }

    // MARK: Init

    init() {
        initializeNowPlayingInfo()
        initializeCommandCenter()
    }
}

// MARK: - RemotePlayer

extension DefaultRemotePlayer: RemotePlayer {
    func getEvents() -> AnyPublisher<RemotePlayerEvent, Error> {
        eventsSubject.eraseToAnyPublisher()
    }

    func updateNowPlaying(_ item: NowPlayable, preferredDuration: Int) -> AnyPublisher<Void, Error> {
        fetchArtwork(for: item)
            .map { [unowned self] artworkImage in
                self.nowPlayingInfoCenter.nowPlayingInfo?[Constant.titleKey] = item.title
                self.nowPlayingInfoCenter.nowPlayingInfo?[Constant.playbackDurationKey] = Double(preferredDuration)
                self.nowPlayingInfoCenter.nowPlayingInfo?[Constant.artworkKey] = MPMediaItemArtwork(
                    boundsSize: artworkImage.size,
                    requestHandler: { _ in artworkImage }
                )
            }
            .eraseToAnyPublisher()
    }

    func updateElapsedTime(_ elapsedTime: Double?) -> AnyPublisher<Void, Error> {
        Just({ nowPlayingInfoCenter.nowPlayingInfo?[Constant.elapsedPlaybackTimeKey] = elapsedTime }())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func updatePlaybackState(isPlaying: Bool) -> AnyPublisher<Void, Error> {
        Just({ nowPlayingInfoCenter.playbackState = isPlaying ? .playing : .paused }())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultRemotePlayer {
    private func initializeNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = [
            Constant.artistKey: appTitle ?? String(),
            Constant.titleKey: String(),
            Constant.artworkKey: MPMediaItemArtwork(
                boundsSize: Constant.defaultImageSize,
                requestHandler: { _ in UIImage() } // TODO: replace UIImage() with logo
            ),
            Constant.playbackRateKey: 1.0,
            Constant.elapsedPlaybackTimeKey: 0,
            Constant.playbackDurationKey: 0
        ]
    }

    private func initializeCommandCenter() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.seekBackwardCommand.isEnabled = true
        commandCenter.seekForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.likeCommand.isEnabled = false
        commandCenter.dislikeCommand.isEnabled = false

        addCommandHandlers()
    }

    private func addCommandHandlers() {
        commandCenter.playCommand.addTarget(handler: commandHandler(for: .play))
        commandCenter.pauseCommand.addTarget(handler: commandHandler(for: .pause))
        commandCenter.nextTrackCommand.addTarget(handler: commandHandler(for: .nextTrack))
        commandCenter.previousTrackCommand.addTarget(handler: commandHandler(for: .previousTrack))
        commandCenter.seekBackwardCommand.addTarget(handler: commandHandler(for: .seekBackward))
        commandCenter.seekForwardCommand.addTarget(handler: commandHandler(for: .seekForward))
        commandCenter.skipBackwardCommand.addTarget(handler: commandHandler(for: .skipBackward))
        commandCenter.skipForwardCommand.addTarget(handler: commandHandler(for: .skipForward))
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            guard let playpackPositionCommanEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.eventsSubject.send(.changePlaybackPosition(playpackPositionCommanEvent.positionTime))
            return .success
        }
        commandCenter.likeCommand.addTarget(handler: commandHandler(for: .likeCommand))
        commandCenter.dislikeCommand.addTarget(handler: commandHandler(for: .dislikeCommand))
    }

    private func commandHandler(for event: RemotePlayerEvent) -> CommandHandler {
        { [unowned self] _ in
            self.eventsSubject.send(event)
            return .success
        }
    }

    private func fetchArtwork(for item: NowPlayable) -> AnyPublisher<UIImage, Error> {
        guard let imageURL = item.imageURL else {
            return Just(UIImage()).setFailureType(to: Error.self).eraseToAnyPublisher() // TODO: replace UIImage() with logo
        }
        return ImagePipeline.shared.imagePublisher(with: imageURL)
            .map { $0.image }
            .catch { _ in Just(UIImage()).setFailureType(to: Error.self).eraseToAnyPublisher() } // TODO: replace UIImage() with logo
            .eraseToAnyPublisher()
    }
}
