//
//  PlayerWidgetViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 18..
//

import Foundation
import Combine

import Common
import Domain

@Observable
final class PlayerWidgetViewModel: ViewModel {

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

    @ObservationIgnored @Injected private var episodeService: EpisodeService
    @ObservationIgnored @Injected private var audioPlayer: AudioPlayer
    @ObservationIgnored @Injected private var socket: Socket

    // MARK: Properties

    private(set) var activeRemotePlayingDeviceText: AttributedString?
    private(set) var episode: Episode?
    private(set) var activeDevicesCount: Int?
    private(set) var isPlaying = false
    private(set) var currentProgress: Float = .zero
    private(set) var isEnabled = true
    private(set) var elapsedTimeText = Constant.emptyProgressText
    private(set) var remainingTimeText = Constant.emptyProgressText
    private(set) var devices = [Device]()
    private(set) var activeDeviceID: String?
    var title: String? { episode?.title }
    var isSliderHighlighted = false
    var currentSliderValue: Float = .zero

    // MARK: Private properties

    @ObservationIgnored private lazy var currentEpisode: AnyPublisher<Episode?, Error> = {
        audioPlayer.getCurrentPlayingAudioInfo()
            .map { $0?.id }
            .flatMapLatest { [unowned self] id -> AnyPublisher<Episode?, Error> in
                guard let id = id else {
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                return episodeService.episode(id: id).eraseToAnyPublisher()
            }
            .shareReplay()
    }()
    @ObservationIgnored private var currentSecondDurationPair: AnyPublisher<SecondDurationPair, Error> {
        return Publishers.CombineLatest(audioPlayer.getCurrentSeconds(), currentEpisode.unwrap())
            .map { (second: $0, duration: $1.duration) }
            .eraseToAnyPublisher()
    }
    @ObservationIgnored private var combinedCurrentSecondDurationPair: AnyPublisher<SecondDurationPair, Error> {
        let isSliderHighlighted = ObservationTrackingPublisher(self.isSliderHighlighted).setFailureType(to: Error.self)
        let currentSliderValue = ObservationTrackingPublisher(self.currentSliderValue).setFailureType(to: Error.self)
        return Publishers.CombineLatest3(currentSecondDurationPair, isSliderHighlighted, currentSliderValue)
            .map { [unowned self] in
                self.getSecondDurationPair(secondDurationPair: $0, isSliderHighlighted: $1, sliderValue: $2)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - View model

extension PlayerWidgetViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeToRemotePlaying() }
            taskGroup.addTask { await self.updateCurrentEpisode() }
            taskGroup.addTask { await self.updatePlayingState() }
            taskGroup.addTask { await self.subscribeToSlider() }
            taskGroup.addTask { await self.updateProgress() }
            taskGroup.addTask { await self.updateEnabledState() }
            taskGroup.addTask { await self.updateTimeTexts() }
            taskGroup.addTask { await self.subscribeToDeviceList() }
            taskGroup.addTask { await self.subscribeToActiveDevice() }
        }
    }
}

// MARK: - Actions

extension PlayerWidgetViewModel {
    func playPlause() {
        Task {
            do {
                let isPlaying = try await audioPlayer.isPlaying().value
                if isPlaying {
                    try await audioPlayer.pause().value
                    try await socket.sendPlaybackCommand(.pause).value
                } else {
                    try await audioPlayer.play().value
                    try await socket.sendPlaybackCommand(.play).value
                }
            } catch {
                return
            }
        }
    }

    func skipBackward() {
        Task {
            try? await audioPlayer.seekBackward().value
            try? await socket.sendPlaybackCommand(.skipBackward).value
        }
    }

    func skipForward() {
        Task {
            try? await audioPlayer.seekForward().value
            try? await socket.sendPlaybackCommand(.skipForward).value
        }
    }

    func setActiveDeviceID(_ activeDeviceID: String) {
        Task {
            try? await socket.sendActiveDevice(activeDeviceID).value
        }
    }
}

// MARK: - Helpers

extension PlayerWidgetViewModel {
    @MainActor
    private func subscribeToRemotePlaying() async {
        let devicesPublisher = socket.getDeviceList().replaceError(with: [])
        let activeDevicePublisher = socket.getActiveDevice().replaceError(with: nil)
        let publisher = Publishers.CombineLatest(devicesPublisher, activeDevicePublisher)

        for await (devices, activeDeviceID) in publisher.asAsyncStream() {
            activeRemotePlayingDeviceText = getActiveRemotePlayingDeviceText(devices: devices, activeDeviceID: activeDeviceID)
            activeDevicesCount = getActiveDevicesCount(devices: devices)
        }
    }

    @MainActor
    private func updateCurrentEpisode() async {
        let publisher = currentEpisode.replaceError(with: nil)
        for await episode in publisher.asAsyncStream() {
            self.episode = episode
        }
    }

    @MainActor
    private func updatePlayingState() async {
        let publisher = audioPlayer.isPlaying().replaceError(with: false)
        for await isPlaying in publisher.asAsyncStream() {
            self.isPlaying = isPlaying
        }
    }

    private func subscribeToSlider() async {
        let isHighlighted = ObservationTrackingPublisher(self.isSliderHighlighted).dropFirst().filter { $0 }
        let notHighlighted = ObservationTrackingPublisher(self.isSliderHighlighted).dropFirst().filter { !$0 }
        let publisher = Publishers.Zip(isHighlighted, notHighlighted)

        do {
            for await _ in publisher.asAsyncStream() {
                currentProgress = currentSliderValue
                let secondDurationPair = try await currentSecondDurationPair.value
                try await audioPlayer.seek(to: Double(currentSliderValue) * Double(secondDurationPair.duration)).value
                try await socket.sendPlaybackCommand(.seek(Double(currentSliderValue))).value
            }
        } catch {
            return
        }
    }

    @MainActor
    private func updateProgress() async {
        do {
            for try await secondDurationPair in currentSecondDurationPair.asAsyncStream() {
                guard !isSliderHighlighted else { return }
                let progress = getProgress(from: secondDurationPair)
                currentProgress = progress
                currentSliderValue = progress
            }
        } catch {
            return
        }
    }

    @MainActor
    private func updateEnabledState() async {
        let publisher = audioPlayer.getCurrentPlayingAudioInfo().replaceError(with: nil)
        for await audioInfo in publisher.asAsyncStream() {
            isEnabled = audioInfo?.id != nil
        }
    }

    @MainActor
    private func updateTimeTexts() async {
        let publisher = combinedCurrentSecondDurationPair.compactMap(\.self).replaceError(with: nil)
        for await secondDurationPair in publisher.asAsyncStream() {
            let (elapsed, remaining): (String, String) = if let secondDurationPair {
                (getProgressTimeText(from: secondDurationPair, type: .elapsed), getProgressTimeText(from: secondDurationPair, type: .remaining))
            } else {
                (Constant.emptyProgressText, Constant.emptyProgressText)
            }
            elapsedTimeText = elapsed
            remainingTimeText = remaining
        }
    }

    @MainActor
    private func subscribeToDeviceList() async {
        let publisher = socket.getDeviceList().removeDuplicates().replaceError(with: [])

        for await devices in publisher.asAsyncStream() {
            self.devices = devices.sorted(by: { $0.connectionTime < $1.connectionTime })
        }
    }

    @MainActor
    private func subscribeToActiveDevice() async {
        let publisher = socket.getActiveDevice().removeDuplicates().replaceError(with: nil)

        for await activeDeviceID in publisher.asAsyncStream() {
            self.activeDeviceID = activeDeviceID
        }
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

    private func getActiveRemotePlayingDeviceText(devices: [Device], activeDeviceID: String?) -> AttributedString? {
        guard let activeDevice = devices.first(where: { $0.id == activeDeviceID }) else { return nil }
        return if !DeviceHelper.isDeviceIDCurrent(activeDevice.id) {
            try? AttributedString(markdown: L10n.listeningOn(activeDevice.name))
        } else {
            nil
        }
    }

    private func getActiveDevicesCount(devices: [Device]) -> Int? {
        if devices.count > 1 {
            devices.count
        } else {
            nil
        }
    }
}
