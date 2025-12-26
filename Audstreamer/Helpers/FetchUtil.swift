//
//  FetchUtil.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 22/06/2024.
//

import Combine

enum FetchUtil {

    // MARK: Dependencies

    @Injected private static var networking: Networking
    @Injected private static var database: Database
    @Injected private static var cloud: Cloud
    @Injected private static var applicationStateHandler: ApplicationStateHandler

    // MARK: Private properties

    private static var isApplicationActive: AnyPublisher<Bool, Error> {
        applicationStateHandler.getState()
            .map { $0 == .active }
            .eraseToAnyPublisher()
    }
}

// MARK: - Internal methods

extension FetchUtil {
    static func fetchData() -> AnyPublisher<Void, Error> {
        let isApplicationActivePublisher = applicationStateHandler.getState().map { $0 == .active }

        return isApplicationActivePublisher
            .first { $0 }
            .flatMap { _ in database.getLastEpisodePublishDate().first() }
            .flatMap { lastPublishDate -> AnyPublisher<([Episode], Int), Error> in
                let remoteEpisodes = networking.getEpisodes(from: lastPublishDate)
                let localEpisodesCount = getEpisodesCount()

                return Publishers.Zip(remoteEpisodes, localEpisodesCount).eraseToAnyPublisher()
            }
            .flatMap { remoteEpisodes, localEpisodesCount in
                let isOverwriteNeeded = remoteEpisodes.count >= localEpisodesCount
                return database.insertEpisodes(remoteEpisodes, overwrite: isOverwriteNeeded)
            }
            .flatMap { synchronizeCloudDataToDatabase() }
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension FetchUtil {
    private static func synchronizeCloudDataToDatabase() -> AnyPublisher<Void, Error> {
        let updateFavorites = updateFavorites()
        let updateLastPlayDates = updateLastPlayedDates()
        let updateLastPositions = updateLastPositions()

        return Publishers.Zip3(updateFavorites, updateLastPlayDates, updateLastPositions).toVoid()
    }

    private static func updateFavorites() -> AnyPublisher<Void, Error> {
        cloud.getFavoriteEpisodeIDs()
            .first()
            .flatMap { ids -> AnyPublisher<Void, Error> in
                guard !ids.isEmpty else { return Just.void() }
                return ids.map { id in
                    database.getEpisode(id: id)
                        .first()
                        .flatMap { episode -> AnyPublisher<Void, Error> in
                            guard let episode = episode else { return Just.void() }
                            return database.updateEpisode(episode, isFavorite: true)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private static func updateLastPlayedDates() -> AnyPublisher<Void, Error> {
        cloud.getLastPlayedDates()
            .first()
            .flatMap { playedDates -> AnyPublisher<Void, Error> in
                guard !playedDates.isEmpty else { return Just.void() }
                return playedDates.map { id, date in
                    database.getEpisode(id: id)
                        .first()
                        .flatMap { episode -> AnyPublisher<Void, Error> in
                            guard let episode = episode else { return Just.void() }
                            return database.updateLastPlayedDate(for: episode, date: date)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private static func updateLastPositions() -> AnyPublisher<Void, Error> {
        cloud.getLastPositions()
            .first()
            .flatMap { lastPositions -> AnyPublisher<Void, Error> in
                guard !lastPositions.isEmpty else { return Just.void() }
                return lastPositions.map { id, lastPosition in
                    database.getEpisode(id: id)
                        .first()
                        .flatMap { episode -> AnyPublisher<Void, Error> in
                            guard let episode = episode else { return Just.void() }
                            return database.updateLastPosition(lastPosition, for: episode)
                        }
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private static func getEpisodesCount() -> AnyPublisher<Int, Error> {
        database.getEpisodes()
            .first()
            .map { $0.count }
            .eraseToAnyPublisher()
    }
}
