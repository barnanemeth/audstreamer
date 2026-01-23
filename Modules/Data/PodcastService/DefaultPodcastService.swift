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

enum DefaultPodcastServiceError: Error {
    case cannotDecodeFeed
}

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

    private lazy var session: URLSession = {
        URLSession(configuration: .ephemeral)
    }()
}

// MARK: - PodcastService

extension DefaultPodcastService: PodcastService {
    func refresh() -> AnyPublisher<Void, Error> {
        syncCloudPodcastsIfNeeded()
            .flatMap { [unowned self] in database.getPodcasts().first() }
            .asyncTryMap { [unowned self] in await contextManager.mapDataModels($0) }
            .flatMap { [unowned self] (podcasts: [Podcast]) in
                guard !podcasts.isEmpty else { return Empty<[[EpisodeDataModel]], Error>(completeImmediately: true).eraseToAnyPublisher() }
                return podcasts.map { assignEpisodesForPodcast(of: $0) }.zip()
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
        .eraseToAnyPublisher()
    }
    
    func getTrending(maximumResult: Int?) -> AnyPublisher<[Podcast], Error> {
        let input = Operations.getTrendingPodcasts.Input(
            query: Operations.getTrendingPodcasts.Input.Query(
                language: "hu",
                max: maximumResult ?? Constant.defaultMaximumResultCount
            )
        )
        return ThrowingAsyncPublisher<Operations.getTrendingPodcasts.Output, Error> {
            try await self.client.getTrendingPodcasts(input)
        }
        .tryMap { response in
            switch response {
            case let .ok(successfulResponse):
                try successfulResponse.body.json.asDomainModels
            case .undocumented:
                throw URLError(.badServerResponse)
            }
        }
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

    func savedPodcasts() -> AnyPublisher<[Podcast], Error> {
        database.getPodcasts()
            .map { $0.asDomainModels }
            .eraseToAnyPublisher()
    }

    func addPodcastFeed(_ feedURL: URL) -> AnyPublisher<Void, Error> {
        var components = URLComponents(url: feedURL, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        components?.queryItems?.sort { $0.name < $1.name }
        let normalizedString = components?.string ?? feedURL.absoluteString

        let id = SHA256.hash(data: normalizedString.data(using: .utf8)!).map { String(format: "%02x", $0) }.joined()

        return fetchAndSavePodcastFromRSSFeed(feedURL, id: id, isPrivate: true)
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

    private func fetchPodcastFromRSSFeed(_ feedURL: URL, id: String, isPrivate: Bool) -> AnyPublisher<PodcastDataModel, Error> {
        session.dataTaskPublisher(for: feedURL)
            .tryMap { [unowned self] data, response in
                try validateResponse(response)
                let feed = try Feed(data: data)
                guard let podcast = feed.rss?.channel?.asDataModel(id: id, rssFeedURL: feedURL, isPrivate: isPrivate) else {
                    throw DefaultPodcastServiceError.cannotDecodeFeed
                }
                return podcast
            }
            .eraseToAnyPublisher()
    }

    private func fetchAndSavePodcastFromRSSFeed(_ feedURL: URL, id: String, isPrivate: Bool) -> AnyPublisher<Void, Error> {
        fetchPodcastFromRSSFeed(feedURL, id: id, isPrivate: isPrivate)
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

    private func assignEpisodesForPodcast(of podcast: Podcast) -> AnyPublisher<[EpisodeDataModel], Error> {
        let fetchResult = fetchPodcastFromRSSFeed(podcast.rssFeedURL, id: podcast.id, isPrivate: podcast.isPrivate)
        let localPodcast = database.getPodcast(id: podcast.id).first()

        return Publishers.Zip(fetchResult, localPodcast)
            .map { fetchResult, localPodcast in
                fetchResult.episodes.map { episode in
                    let episode = episode
                    episode.podcast = localPodcast
                    return episode
                }
            }
            .eraseToAnyPublisher()
    }
}
