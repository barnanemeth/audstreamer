//
//  LoadingScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation
import Combine

final class LoadingScreenViewModel: ScreenViewModel {

    // MARK: Constants

    private enum Constant {
        static let navigationDelay: DispatchQueue.SchedulerTimeType.Stride = 1
    }

    // MARK: Typealiases

    private typealias EpisodeFavorite = (episode: EpisodeData, isFavorite: Bool)

    // MARK: Dependencies

    @Injected private var networking: Networking
    @Injected private var database: Database
    @Injected private var cloud: Cloud
    @Injected private var account: Account
    @Injected private var applicationStateHandler: ApplicationStateHandler

    // MARK: Properties

    @Published var isLoading = false
    var navigateToPlayerScreenAction: CocoaAction?
    var navigateToLoginScreenAction: CocoaAction?
    var presentErrorAlertAction: Action<Error, Never>?

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var isApplicationActive: AnyPublisher<Bool, Error> {
        applicationStateHandler.getState()
            .map { $0 == .active }
            .eraseToAnyPublisher()
    }
}

// MARK: - Actions

extension LoadingScreenViewModel {
    func fetchData() {
        isApplicationActive
            .first { $0 }
            .flatMap { [unowned self] _ in self.database.getLastEpisodePublishDate().first() }
            .flatMap { [unowned self] lastPublishDate -> AnyPublisher<([EpisodeData], Int), Error> in
                let remoteEpisodes = self.networking.getEpisodes(from: lastPublishDate)
                let localEpisodesCount = self.getEpisodesCount()

                return Publishers.Zip(remoteEpisodes, localEpisodesCount).eraseToAnyPublisher()
            }
            .flatMap { [unowned self] remoteEpisodes, localEpisodesCount in
                let isOverwriteNeeded = remoteEpisodes.count >= localEpisodesCount
                return self.database.insertEpisodes(remoteEpisodes, overwrite: isOverwriteNeeded)
            }
            .flatMap { [unowned self] in self.synchronizeCloudDataToDatabase() }
            .delay(for: Constant.navigationDelay, scheduler: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [unowned self] _ in self.isLoading = true },
                          receiveCompletion: { [unowned self] _ in self.isLoading = false })
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished: self.navigateNext()
                case let.failure(error): self.presentErrorAlertAction?.execute(error)
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension LoadingScreenViewModel {
    private func synchronizeCloudDataToDatabase() -> AnyPublisher<Void, Error> {
        let updateFavorites = updateFavorites()
        let updateLastPlayDates = updateLastPlayedDates()
        let updateLastPositions = updateLastPositions()

        return Publishers.Zip3(updateFavorites, updateLastPlayDates, updateLastPositions).toVoid()
    }

    private func updateFavorites() -> AnyPublisher<Void, Error> {
        cloud.getFavoriteEpisodeIDs()
            .first()
            .flatMap { [unowned self] ids -> AnyPublisher<Void, Error> in
                guard !ids.isEmpty else { return Just.void() }
                return ids.map { id in
                    self.database.getEpisode(id: id)
                        .first()
                        .flatMap { [unowned self] episode -> AnyPublisher<Void, Error> in
                            guard let episode = episode else { return Just.void() }
                            return self.database.updateEpisode(episode, isFavorite: true)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private func updateLastPlayedDates() -> AnyPublisher<Void, Error> {
        cloud.getLastPlayedDates()
            .first()
            .flatMap { [unowned self] playedDates -> AnyPublisher<Void, Error> in
                guard !playedDates.isEmpty else { return Just.void() }
                return playedDates.map { id, date in
                    self.database.getEpisode(id: id)
                        .first()
                        .flatMap { [unowned self] episode -> AnyPublisher<Void, Error> in
                            guard let episode = episode else { return Just.void() }
                            return self.database.updateLastPlayedDate(for: episode, date: date)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private func updateLastPositions() -> AnyPublisher<Void, Error> {
        cloud.getLastPositions()
            .first()
            .flatMap { [unowned self] lastPositions -> AnyPublisher<Void, Error> in
                guard !lastPositions.isEmpty else { return Just.void() }
                return lastPositions.map { id, lastPosition in
                    self.database.getEpisode(id: id)
                        .first()
                        .flatMap { [unowned self] episode -> AnyPublisher<Void, Error> in
                            guard let episode = episode else { return Just.void() }
                            return self.database.updateLastPosition(lastPosition, for: episode)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private func navigateNext() {
        account.refresh()
            .flatMap { [unowned self] in self.account.isLoggedIn().first() }
            .map { [unowned self] in $0 ? self.navigateToPlayerScreenAction : self.navigateToLoginScreenAction }
            .sink { $0?.execute() }
            .store(in: &cancellables)
    }

    private func getEpisodesCount() -> AnyPublisher<Int, Error> {
        database.getEpisodes()
            .first()
            .map { $0.count }
            .eraseToAnyPublisher()
    }
}
