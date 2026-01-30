//
//  DefaultPodcastService.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 20..
//

import Foundation
import Combine
import CryptoKit

import Common
import Domain

internal import AudstreamerAPIClient
internal import FeedKit
internal import XMLKit

final class DefaultPodcastService {

    // MARK: Constants

    private enum Constant {
        static let defaultMaximumResultCount = 100
    }

    // MARK: Dependencies

    @Injected private var client: Client
    @Injected private var database: Database
    @Injected private var cloud: Cloud
    @Injected private var contextManager: SwiftDataContextManager

    // MARK: Private properties

    private var trendingCache = [Int: [Podcast]]()
    private var searchCache = Set<Podcast>()
    private let session = URLSession(configuration: .ephemeral)
}

// MARK: - PodcastService

extension DefaultPodcastService: PodcastService {
    func refresh() -> AnyPublisher<Void, Error> {
        syncCloudPodcastsIfNeeded()
            .flatMap { [unowned self] in database.getPodcasts().first() }
            .asyncTryMap { [unowned self] in await contextManager.mapDataModels($0) }
            .flatMap { [unowned self] (podcasts: [Podcast]) in
                guard !podcasts.isEmpty else { return Empty<[[EpisodeDataModel]], Error>(completeImmediately: true).eraseToAnyPublisher() }
                return podcasts.map { assignNewEpisodesForPodcast($0) }.zip()
            }
            .map { $0.flatMap { $0 } }
            .flatMap { [unowned self] in
                database.insertEpisodes($0, overwrite: false)
            }
            .replaceEmpty(with: ())
            .eraseToAnyPublisher()
    }

    func search(with searchTerm: String) -> AnyPublisher<[Podcast], Error> {
        let input = Operations.searchPodcasts.Input(
            query: Operations.searchPodcasts.Input.Query(
                term: searchTerm,
                max: Constant.defaultMaximumResultCount
            )
        )
        return ThrowingAsyncPublisher<Operations.searchPodcasts.Output, Error> {
            try await self.client.searchPodcasts(input)
        }
        .tryMap { response in
            switch response {
            case let .ok(successfulResponse):
                try successfulResponse.body.json.asDomainModels
            case .undocumented:
                throw URLError(.badServerResponse)
            }
        }
        .handleEvents(receiveOutput: { [unowned self] in
            searchCache.formUnion($0)
        })
        .eraseToAnyPublisher()
    }

    func podcast(id: Podcast.ID) -> AnyPublisher<Podcast?, Error> {
        database.getPodcast(id: id)
            .asyncTryMap { [unowned self] in await contextManager.mapDataModel($0) }
            .map { [unowned self] savedPodcast in
                if let savedPodcast {
                    savedPodcast
                } else {
                    trendingCache.first?.value.first(where: { $0.id == id }) ?? searchCache.first(where: { $0.id == id })
                }
            }
            .eraseToAnyPublisher()
    }

    func getTrending(maximumResult: Int?) -> AnyPublisher<[Podcast], Error> {
        let maximumResult = maximumResult ?? Constant.defaultMaximumResultCount

        if let cachedPodcasts = trendingCache[maximumResult] {
            return Just(cachedPodcasts).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        return getPreferredLanguage()
            .flatMap { [unowned self] language in
                let input = Operations.getTrendingPodcasts.Input(
                    query: Operations.getTrendingPodcasts.Input.Query(
                        language: Locale.current.region?.identifier,
                        max: maximumResult
                    )
                )
                return ThrowingAsyncPublisher<Operations.getTrendingPodcasts.Output, Error> {
                    try await self.client.getTrendingPodcasts(input)
                }
            }
            .tryMap { response in
                switch response {
                case let .ok(successfulResponse):
                    try successfulResponse.body.json.asDomainModels
                case .undocumented:
                    throw URLError(.badServerResponse)
                }
            }
            .handleEvents(receiveOutput: { [unowned self] podcasts in
                trendingCache.removeAll()
                trendingCache[maximumResult] = podcasts
            })
            .eraseToAnyPublisher()
    }
    
    func subscribe(to podcast: Podcast) -> AnyPublisher<Void, Error> {
        fetchAndSavePodcastFromRSSFeed(podcast.rssFeedURL, id: podcast.id, isPrivate: false)
            .flatMap { [unowned self] in cloud.setPodcastSubscription(podcast, to: true) }
            .eraseToAnyPublisher()
    }
    
    func unsubscribe(from podcast: Podcast) -> AnyPublisher<Void, Error> {
        database.deletePodcast(podcast.id)
            .flatMap { [unowned self] in cloud.setPodcastSubscription(podcast, to: false) }
            .eraseToAnyPublisher()
    }

    func savedPodcasts(sortingPreference: PodcastSortingPreference?) -> AnyPublisher<[Podcast], Error> {
        database.getPodcasts()
            .asyncTryMap { [unowned self] podcasts in
                await contextManager.block {
                    if let sortingPreference {
                        podcasts.sorted(by: sortComparator(for: sortingPreference))
                    } else {
                        podcasts
                    }
                }
            }
            .map { $0.asDomainModels }
            .eraseToAnyPublisher()
    }

    func addPodcastFeed(_ feedURL: URL) -> AnyPublisher<Void, Error> {
        var components = URLComponents(url: feedURL, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        components?.queryItems?.sort { $0.name < $1.name }
        let normalizedString = components?.string ?? feedURL.absoluteString

        let id = SHA256.hash(data: normalizedString.data(using: .utf8)!).map { String(format: "%02x", $0) }.joined()

        return isPodcastsExists(with: id)
            .flatMap { [unowned self] isExists in
                if isExists {
                    Fail<Void, Error>(error: PodcastServiceError.alreadyExists).eraseToAnyPublisher()
                } else {
                    fetchAndSavePodcastFromRSSFeed(feedURL, id: id, isPrivate: true)
                }
            }
            .flatMap { [unowned self] in database.getPodcast(id: id).first() }
            .asyncTryMap { [unowned self] in await contextManager.mapDataModel($0) }
            .flatMap { [unowned self] podcast in
                guard let podcast else { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
                return cloud.setPodcastSubscription(podcast, to: true)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultPodcastService {
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    private func fetchPodcastFromRSSFeed(_ feedURL: URL) -> AnyPublisher<PodcastRSSModel, Error> {
        session.dataTaskPublisher(for: feedURL)
            .tryMap { [unowned self] data, response in
                try validateResponse(response)
                let feed = try Feed(data: data)
                guard let podcast = feed.rss?.channel else {
                    throw PodcastServiceError.cannotDecodeFeed
                }
                return podcast
            }
            .eraseToAnyPublisher()
    }

    private func fetchPodcastFromRSSFeedAndMapToDataModel(_ feedURL: URL, id: String, isPrivate: Bool) -> AnyPublisher<PodcastDataModel, Error> {
        fetchPodcastFromRSSFeed(feedURL)
            .tryMap { podcast in
                guard let podcast = podcast.asDataModel(id: id, rssFeedURL: feedURL, isPrivate: isPrivate) else {
                    throw PodcastServiceError.cannotDecodeFeed
                }
                return podcast
            }
            .eraseToAnyPublisher()
    }

    private func fetchEpisodesFromRSSFeed(_ feedURL: URL) -> AnyPublisher<[EpisodeRSSModel], Error> {
        fetchPodcastFromRSSFeed(feedURL)
            .map { $0.items ?? [] }
            .eraseToAnyPublisher()
    }

    private func fetchAndSavePodcastFromRSSFeed(_ feedURL: URL, id: String, isPrivate: Bool) -> AnyPublisher<Void, Error> {
        fetchPodcastFromRSSFeedAndMapToDataModel(feedURL, id: id, isPrivate: isPrivate)
            .flatMap { [unowned self] in database.insertPodcasts([$0]) }
            .eraseToAnyPublisher()
    }

    private func syncCloudPodcastsIfNeeded() -> AnyPublisher<Void, Error> {
        let podcastSubscriptions = cloud.getPodcastSubscriptions().first().replaceError(with: [:]).setFailureType(to: Error.self)
        let localPodcasts = database.getPodcasts().first()

        return Publishers.Zip(podcastSubscriptions, localPodcasts)
            .flatMap { [unowned self] subscriptions, localPodcasts in
                let localPodcastIDs = localPodcasts.map(\.id)
                let nonExistingSubscriptions = subscriptions.filter { !localPodcastIDs.contains($0.key) }

                guard !nonExistingSubscriptions.isEmpty else { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
                return nonExistingSubscriptions.map { id, item in
                    let rssFeedURL = item.rssFeedURL
                    let isPrivate = item.isPrivate
                    return fetchAndSavePodcastFromRSSFeed(rssFeedURL, id: id, isPrivate: isPrivate)
                }
                .zip()
                .toVoid()
            }
            .eraseToAnyPublisher()
    }

    private func assignNewEpisodesForPodcast(_ podcast: Podcast) -> AnyPublisher<[EpisodeDataModel], Error> {
        let remoteEpisodes = fetchEpisodesFromRSSFeed(podcast.rssFeedURL)
        let localPodcast = database.getPodcast(id: podcast.id).first()

        return Publishers.Zip(remoteEpisodes, localPodcast)
            .asyncTryMap { [unowned self] remoteEpisodes, localPodcast -> [EpisodeDataModel] in
                await contextManager.block {
                    guard let localPodcast else { return [] }

                    let localIDs = localPodcast.episodes.map(\.id)
                    let newEpisodes = remoteEpisodes
                        .filter { episode in
                            guard let id = episode.guid?.text else { return false }
                            return !localIDs.contains(id)
                        }

                    let dataModels = newEpisodes.asDataModels
                    for episode in dataModels {
                        episode.podcast = localPodcast
                    }
                    return dataModels
                }
            }
            .eraseToAnyPublisher()
    }

    private func isPodcastsExists(with id: Podcast.ID) -> AnyPublisher<Bool, Error> {
        database.getPodcast(id: id)
            .first()
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }

    private func sortComparator(for sortingPreference: PodcastSortingPreference) -> (PodcastDataModel, PodcastDataModel) -> Bool {
        switch sortingPreference {
        case .byLatestRelease:
            { lhs, rhs in
                (lhs.episodes.map(\.publishDate).max() ?? .distantPast) >
                (rhs.episodes.map(\.publishDate).max() ?? .distantPast)
            }
        case .byLatestInteraction:
            { lhs, rhs in
                (lhs.episodes.map { $0.lastPlayed ?? $0.publishDate }.max() ?? .distantPast) >
                (rhs.episodes.map { $0.lastPlayed ?? $0.publishDate }.max() ?? .distantPast)
            }
        case let.byTitle(ascending):
            if ascending {
                { $0.title > $1.title }
            } else {
                { $0.title < $1.title }
            }
        }
    }

    private func getPreferredLanguage() -> AnyPublisher<String, Error> {
        database.getPodcasts()
            .first()
            .asyncTryMap { [unowned self] in await contextManager.mapDataModels($0) }
            .map { pocasts in
                let languages = pocasts.compactMap(\.language).compactMap { $0.components(separatedBy: "-").first?.lowercased() }
                let languageCounts = languages.reduce(into: [String: Int]()) { languageCounts, language in
                    if languageCounts[language] != nil {
                        languageCounts[language]! += 1
                    } else {
                        languageCounts[language] = 1
                    }
                }
                let mostCommonLanguage = languageCounts.max(by: { $0.value < $1.value })?.key

                return mostCommonLanguage ?? Locale.current.language.languageCode?.identifier ?? Locale.preferredLanguages.first ?? Locale.current.identifier
            }
            .eraseToAnyPublisher()
    }
}
