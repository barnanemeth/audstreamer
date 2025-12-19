//
//  WatchEpisodeService+Helpers.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 14..
//

import Foundation
import Combine

// MARK: - Helpers

extension WatchEpisodeService {
    func setupSession() {
        session.delegate = self
        session.activate()
    }

    func setpInitialEpisodeData() {
        setEpisodeDataFromApplicationContext(session.applicationContext)
    }

    func setEpisodeDataFromApplicationContext(_ applicationContext: [String: Any]) {
        let episodes = mapEpisodes(from: applicationContext[Constant.episodesMessageKey] as? [[String: Any]])
        guard let episodeData = try? encoder.encode(episodes) else { return }
        userDefaults.episodesData = episodeData
    }

    func mapEpisodes(from dictionaryArray: [[String: Any]]?) -> [EpisodeCommon] {
        guard let dictionaryArray else { return [] }
        return dictionaryArray.compactMap { EpisodeCommon(from: $0) }
    }

    func decodeEpisodes(from data: Data?) throws -> [EpisodeCommon] {
        guard let data else { return [] }
        return try decoder.decode([EpisodeCommon].self, from: data)
    }

    func setupDeleteOrDownloadSubscription() {
        let activtionStatePublisher = session.publisher(for: \.activationState).toVoid()
        let isReachablePublisher = session.publisher(for: \.isReachable).toVoid()

        Publishers.Merge(activtionStatePublisher, isReachablePublisher)
            .throttle(for: 0.5, scheduler: DispatchQueue.global(qos: .background), latest: true)
            .map { [unowned self] in self.episodes.replaceError(with: []).removeDuplicates() }
            .switchToLatest()
            .scan(EpisodeHistory(), { $0.appending($1) })
            .flatMap { [unowned self] in self.deleteEpisodes(by: $0) }
            .sink()
            .store(in: &cancellables)
    }

    func deleteEpisodes(by episodeHistory: EpisodeHistory) -> AnyPublisher<Void, Error> {
        let currentEpisodes = episodeHistory.current ?? []
        let nextEpisodes = episodeHistory.next ?? []

        let difference = nextEpisodes.difference(from: currentEpisodes)

        let publishers = difference.compactMap { difference -> AnyPublisher<Void, Error>? in
            guard case let .remove(_, episode, _) = difference else { return nil }
            return deleteEpisodeIfNeeded(episode)
        }

        return if publishers.isEmpty {
            Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        } else {
            publishers.zip().toVoid().eraseToAnyPublisher()
        }

    }

    func deleteEpisodeIfNeeded(_ episode: EpisodeCommon) -> AnyPublisher<Void, Error> {
        isDownloaded(episode)
            .flatMap { [unowned self] _ in self.delete(episode) }
            .replaceError(with: ())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

//    func downloadEpisodeIfNeeded(_ episode: EpisodeCommon) -> AnyPublisher<Void, Error> {
//        isDownloaded(episode)
//            .flatMap { [unowned self] isDownloaded -> AnyPublisher<Void, Error> in
//                guard !isDownloaded else { return Just.void() }
//                return self.download(episode)
//            }
//            .eraseToAnyPublisher()
//    }

    func cancelOutstandingLastPlayedDateTransfers<T: WatchConnectivityEpisodeBasedMessage>(
        for episodeID: String,
        type: T.Type
    ) -> AnyPublisher<Void, Error> {
        session.outstandingUserInfoTransfers.forEach { transfer in
            guard let message = T(from: transfer.userInfo), message.episodeID == episodeID else { return }
            transfer.cancel()
        }

        return Just.void()
    }

    func updateDownloadedState(of episodeID: String, isDownloaded: Bool) {
        do {
            var episodes = try decodeEpisodes(from: userDefaults.episodesData)
            guard let index = episodes.firstIndex(where: { $0.id == episodeID }) else { return }
            episodes[index].isDownloaded = isDownloaded

            let data = try encoder.encode(episodes)
            userDefaults.episodesData = data
        } catch {
            print("Cannot update downloaded state for episode with ID: \(episodeID)")
        }
    }
}
