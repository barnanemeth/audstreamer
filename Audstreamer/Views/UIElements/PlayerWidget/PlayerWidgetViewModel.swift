//
//  PlayerWidgetViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 18..
//

import Foundation
import Combine

final class PlayerWidgetViewModel {

    // MARK: Typealiases

    private typealias SecondDurationPair = (second: Second, duration: Int)

    // MARK: Enums

    private enum ProgressTimeTextType {
        case elapsed
        case remaining
    }

    // MARK: Constants

    private enum Constant {
        static let emptyProgressText = "--:--:--"
    }

    // MARK: Dependencies

    @Injected private var database: Database
    @Injected private var audioPlayer: AudioPlayer
    @Injected private var socket: Socket

    // MARK: Properties

    @Published var isLoading = false
    @Published var isSliderHighlighted = false
    @Published var currentSliderValue: Float = .zero
    lazy var playPauseAction = CocoaAction(PlayerWidgetViewModel.playPlause, in: self)
    lazy var skipBackwardAction = CocoaAction(PlayerWidgetViewModel.skipBackward, in: self)
    lazy var skipForwardAction = CocoaAction(PlayerWidgetViewModel.skipForward, in: self)
    var title: AnyPublisher<String, Never> {
        currentEpisode
            .compactMap { $0?.title }
            .replaceError(with: String())
            .eraseToAnyPublisher()
    }
    var currentProgress: AnyPublisher<Float, Never> {
        currentSecondDurationPair
            .map { [unowned self] in self.getProgress(from: $0) }
            .replaceError(with: .zero)
            .eraseToAnyPublisher()
    }
    var elapsedText: AnyPublisher<String, Never> {
        combinedCurrentSecondDurationPair
            .map { [unowned self] in self.getProgressTimeText(from: $0, type: .elapsed) }
            .replaceError(with: Constant.emptyProgressText)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    var remainingText: AnyPublisher<String, Never> {
        combinedCurrentSecondDurationPair
            .map { [unowned self] in self.getProgressTimeText(from: $0, type: .remaining) }
            .replaceError(with: Constant.emptyProgressText)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    var isEnabled: AnyPublisher<Bool, Never> {
        audioPlayer.getCurrentPlayingAudioInfo()
            .map { $0 != nil }
            .flatMap { [unowned self] isCurrentExists -> AnyPublisher<(Bool, Bool), Error> in
                let isCurrentExistsPublisher = Just(isCurrentExists).setFailureType(to: Error.self)
                let isLoading = self.$isLoading.setFailureType(to: Error.self).first()

                return Publishers.Zip(isCurrentExistsPublisher, isLoading).eraseToAnyPublisher()
            }
            .map { $0 && !$1 }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
    var isPlaying: AnyPublisher<Bool, Never> {
        audioPlayer.isPlaying()
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
    var activeDevicesCount: AnyPublisher<Int, Never> {
        socket.getDeviceList()
            .map { $0.count }
            .replaceError(with: .zero)
            .eraseToAnyPublisher()
    }
    var currentActiveDevice: AnyPublisher<Device?, Never> {
        Publishers.CombineLatest(socket.getDeviceList(), socket.getActiveDevice())
            .map { deviceList, activeDeviceID in
                deviceList.first(where: { $0.id == activeDeviceID })
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private lazy var currentEpisode: AnyPublisher<Episode?, Error> = {
        audioPlayer.getCurrentPlayingAudioInfo()
            .map { $0?.id }
            .flatMapLatest { [unowned self] id -> AnyPublisher<Episode?, Error> in
                guard let id = id else {
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                return self.database.getEpisode(id: id).eraseToAnyPublisher()
            }
            .shareReplay()
            .eraseToAnyPublisher()
    }()
    private var currentSecondDurationPair: AnyPublisher<SecondDurationPair, Error> {
        return Publishers.CombineLatest(audioPlayer.getCurrentSeconds(), currentEpisode.unwrap())
            .map { (second: $0, duration: $1.duration) }
            .eraseToAnyPublisher()
    }
    private var combinedCurrentSecondDurationPair: AnyPublisher<SecondDurationPair, Error> {
        let isSliderHighlighted = $isSliderHighlighted.setFailureType(to: Error.self)
        let currentSliderValue = $currentSliderValue.setFailureType(to: Error.self)
        return Publishers.CombineLatest3(currentSecondDurationPair, isSliderHighlighted, currentSliderValue)
            .map { [unowned self] in
                self.getSecondDurationPair(secondDurationPair: $0, isSliderHighlighted: $1, sliderValue: $2)
            }
            .eraseToAnyPublisher()
    }

    // MARK: Init

    init() {
        subscribeToSlider()
    }
}

// MARK: - Actions

extension PlayerWidgetViewModel {
    private func playPlause() {
        audioPlayer.isPlaying()
            .first()
            .flatMap { [unowned self] isPlaying -> AnyPublisher<Void, Error> in
                let audioPlayer: AnyPublisher<Void, Error>
                let socket: AnyPublisher<Void, Error>

                if !isPlaying {
                    audioPlayer = self.audioPlayer.play()
                    socket = self.socket.sendPlaybackCommand(.play)
                } else {
                    audioPlayer = self.audioPlayer.pause()
                    socket = self.socket.sendPlaybackCommand(.pause)
                }

                return Publishers.Zip(audioPlayer, socket).toVoid()
            }
            .sink()
            .store(in: &cancellables)
    }

    private func skipBackward() {
        Publishers.Zip(audioPlayer.seekBackward(), socket.sendPlaybackCommand(.skipBackward))
            .sink()
            .store(in: &cancellables)
    }

    private func skipForward() {
        Publishers.Zip(audioPlayer.seekForward(), socket.sendPlaybackCommand(.skipForward))
            .sink()
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension PlayerWidgetViewModel {
    private func subscribeToSlider() {
        let isHighlighted = $isSliderHighlighted.dropFirst().filter { $0 }
        let notHighlighted = $isSliderHighlighted.dropFirst().filter { !$0 }

        Publishers.Zip(isHighlighted, notHighlighted)
            .setFailureType(to: Error.self)
            .toVoid()
            .flatMap { [unowned self] _ -> AnyPublisher<(Float, Int), Error> in
                let sliderValue = self.$currentSliderValue.setFailureType(to: Error.self).first()
                let currentDuration = self.currentSecondDurationPair.first().map { $0.duration }

                return Publishers.Zip(sliderValue, currentDuration).eraseToAnyPublisher()
            }
            .flatMap { [unowned self] sliderValue, duration in
                let audioPlayer = self.audioPlayer.seek(to: Double(sliderValue) * Double(duration))
                let socket = self.socket.sendPlaybackCommand(.seek(Double(sliderValue)))

                return Publishers.Zip(audioPlayer, socket).eraseToAnyPublisher()
            }
            .sink()
            .store(in: &cancellables)
    }

    private func getProgress(from secondDurationPair: SecondDurationPair) -> Float {
        Float(secondDurationPair.second) / Float(secondDurationPair.duration)
    }

    private func getSecondDurationPair(secondDurationPair: SecondDurationPair,
                                       isSliderHighlighted: Bool,
                                       sliderValue: Float) -> SecondDurationPair {
        var secondDurationPair = secondDurationPair
        if isSliderHighlighted {
            secondDurationPair.second = Second(Float(secondDurationPair.duration) * sliderValue)
        }
        return secondDurationPair
    }

    private func getProgressTimeText(from secondDurationPair: SecondDurationPair,
                                     type: ProgressTimeTextType) -> String {
        switch type {
        case .elapsed:
            return secondDurationPair.second.secondsToHoursMinutesSecondsString
        case .remaining:
            let remaining = Double(secondDurationPair.duration) - secondDurationPair.second
            return ("-\(remaining.secondsToHoursMinutesSecondsString)")
        }
    }
}
