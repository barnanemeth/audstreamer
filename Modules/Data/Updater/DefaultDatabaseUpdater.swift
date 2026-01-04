//
//  DefaultDatabaseUpdater.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 23..
//

import Foundation
import Combine

import Common
import Domain

final class DefaultDatabaseUpdater {

    // MARK: Constants

    private enum Constant {
        static let lastPositionUpdateInterval: DispatchQueue.SchedulerTimeType.Stride = 2
    }

    // MARK: Dependencies

    @Injected private var audioPlayer: AudioPlayer
    @Injected private var database: Database
    @Injected private var cloud: Cloud
    @Injected private var downloadService: DownloadService

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private lazy var currentPlayingEpisode: AnyPublisher<Episode, Error> = {
        audioPlayer.getCurrentPlayingAudioInfo()
            .compactMap { $0?.id }
            .flatMap { [unowned self] in self.database.getEpisode(id: $0).unwrap().first() }
            .shareReplay()
            .eraseToAnyPublisher()
    }()
}

// MARK: - DatabaseUpdater

extension DefaultDatabaseUpdater: DatabaseUpdater {
    func startUpdating() -> AnyPublisher<Void, Error> {
        Just(start()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func stopUpdating() -> AnyPublisher<Void, Error> {
        Just(stop()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultDatabaseUpdater {
    private func start() {
        guard cancellables.isEmpty else { return }
        subscribeToCurrentPlayingEpisode()
        subscribeToCurrentSeconds()
        setupDurationSubscription()
        setupPlayingFinishedSubscription()
        setupDownloadSubscription()
    }

    private func stop() {
        cancellables.removeAll()
    }

    private func subscribeToCurrentPlayingEpisode() {
        currentPlayingEpisode
            .flatMap { [unowned self] episode in
                let lastPlayedDateDatabaseUpdate = self.database.updateLastPlayedDate(for: episode)
                let numberOfPlaysDatabaseUpdate = self.database.incrementNumberOfPlays(of: episode)
                let lastPlayedDateCloudUpdate = self.cloud.setLastPlayedDate(Date(), for: episode.id)
                let numberOfPlaysCloudUpdate = self.cloud.setNumberOfPlays(episode.numberOfPlays + 1, for: episode.id)

                return Publishers.Zip4(
                    lastPlayedDateDatabaseUpdate,
                    numberOfPlaysDatabaseUpdate,
                    lastPlayedDateCloudUpdate,
                    numberOfPlaysCloudUpdate
                )
                .toVoid()
            }
            .sink()
            .store(in: &cancellables)
    }

    private func subscribeToCurrentSeconds() {
        audioPlayer.getCurrentSeconds()
            .throttle(for: Constant.lastPositionUpdateInterval, scheduler: DispatchQueue.main, latest: true)
            .flatMap { [unowned self] seconds -> AnyPublisher<(Second, Episode), Error> in
                let secondsPublisher = Just(seconds).setFailureType(to: Error.self)
                let currentPlayingEpisode = self.currentPlayingEpisode.first()

                return Publishers.Zip(secondsPublisher, currentPlayingEpisode).eraseToAnyPublisher()
            }
            .flatMap { [unowned self] second, episode -> AnyPublisher<Void, Error> in
                guard second.isNormal else { return Just.void() }
                let intSecond = Int(second)

                let databaseUpdate = self.database.updateLastPosition(intSecond, for: episode)
                let cloudUpdate = self.cloud.setLastPosition(intSecond, for: episode.id)

                return Publishers.Zip(databaseUpdate, cloudUpdate).toVoid()
            }
            .sink()
            .store(in: &cancellables)
    }

    private func setupDurationSubscription() {
        audioPlayer.getCurrentPlayingAudioInfo()
            .unwrap()
            .flatMap { [unowned self] audioInfo -> AnyPublisher<(Int, Episode?), Error> in
                let durationPublisher = Just(audioInfo.duration).setFailureType(to: Error.self)
                let episode = self.database.getEpisode(id: audioInfo.id).first()

                return Publishers.Zip(durationPublisher, episode).eraseToAnyPublisher()
            }
            .flatMap { [unowned self] duration, episode -> AnyPublisher<Void, Error> in
                guard let episode = episode, episode.duration != duration else { return Just.void() }
                return self.database.updateDuration(duration, for: episode)
            }
            .sink()
            .store(in: &cancellables)
    }

    private func setupPlayingFinishedSubscription() {
        audioPlayer.getPlayingFinishedAudioInfo()
            .flatMap { [unowned self] audioInfo -> AnyPublisher<(Episode?, Int), Error> in
                let episode = self.database.getEpisode(id: audioInfo.id).first()
                let duration = Just(audioInfo.duration).setFailureType(to: Error.self)

                return Publishers.Zip(episode, duration).eraseToAnyPublisher()
            }
            .flatMap { [unowned self] episode, duration -> AnyPublisher<Void, Error> in
                guard let episode = episode else { return Just.void() }

                let databaseUpdate = self.database.updateLastPosition(duration, for: episode)
                let cloudUpdate = self.cloud.setLastPosition(duration, for: episode.id)

                return Publishers.Zip(databaseUpdate, cloudUpdate).toVoid()
            }
            .sink()
            .store(in: &cancellables)
    }

    private func setupDownloadSubscription() {
        downloadService.getEvent()
            .filter { event in
                guard !event.item.isSilentDownloading,
                      case .finished = event else { return false }
                return true
            }
            .flatMap { [unowned self] in self.database.getEpisode(id: $0.item.id).unwrap().first() }
            .flatMap { [unowned self] in self.database.updateEpisode($0, isDownloaded: true) }
            .sink()
            .store(in: &cancellables)
    }
}
