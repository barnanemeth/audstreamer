//
//  SwiftDataDatabase.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 04..
//

import Foundation
import Combine
import SwiftData

import Common
import Domain

internal import CompoundPredicate

final class SwiftDataDatabase {

    // MARK: Dependencies

    @Injected private var contextManager: SwiftDataContextManager
}

// MARK: - Database

extension SwiftDataDatabase: Database {
    func insertEpisodes(_ episodes: [EpisodeDataModel], overwrite: Bool) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.contextManager.insert(episodes, ignoreIfExists: !overwrite)
        }
        .eraseToAnyPublisher()
    }

    func getEpisodes(filterFavorites: Bool,
                     filterDownloads: Bool,
                     filterWatch: Bool,
                     keyword: String?,
                     podcastID: PodcastDataModel.ID?) -> AnyPublisher<[EpisodeDataModel], Error> {
        var predicates = [Predicate<EpisodeDataModel>]()

        if let keyword = keyword?.lowercased() {
            let predicate = #Predicate<EpisodeDataModel> { episode in
                episode.title.localizedStandardContains(keyword) ||
                episode.descriptionText?.localizedStandardContains(keyword) == true
            }
            predicates.append(predicate)
        }

        if filterFavorites {
            predicates.append(#Predicate<EpisodeDataModel> { $0.isFavourite })
        }

        if filterDownloads {
            predicates.append(#Predicate<EpisodeDataModel> { $0.isDownloaded })
        }

        if filterWatch {
            predicates.append(#Predicate<EpisodeDataModel> { $0.isOnWatch })
        }

        if let podcastID {
            predicates.append(#Predicate<EpisodeDataModel> { $0.podcast?.id == podcastID })
        }

        let combinedPredicate = predicates.conjunction()

        var descriptor = FetchDescriptor<EpisodeDataModel>(
            predicate: combinedPredicate,
            sortBy: [.init(\.publishDate, order: .reverse)]
        )
        descriptor.relationshipKeyPathsForPrefetching = []

        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .eraseToAnyPublisher()
    }

    func getEpisode(id: String) -> AnyPublisher<EpisodeDataModel?, Error> {
        let targetId = id
        var descriptor = FetchDescriptor<EpisodeDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .map { $0.first }
            .eraseToAnyPublisher()
    }
    
    func getLastEpisodePublishDate() -> AnyPublisher<Date?, Error> {
        var descriptor = FetchDescriptor<EpisodeDataModel>(
            sortBy: [.init(\.publishDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .map { $0.first?.publishDate }
            .eraseToAnyPublisher()
    }
    
    func getLastPlayedEpisode() -> AnyPublisher<EpisodeDataModel?, Error> {
        var descriptor = FetchDescriptor<EpisodeDataModel>(
            sortBy: [.init(\.lastPlayed, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .map { $0.first }
            .eraseToAnyPublisher()
    }
    
    func updateEpisode(_ episode: EpisodeDataModel.ID, isFavorite: Bool) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode, keyPath: \.isFavourite, to: isFavorite)
        }
        .eraseToAnyPublisher()
    }
    
    func updateEpisode(_ episode: EpisodeDataModel.ID, isOnWatch: Bool) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode, keyPath: \.isOnWatch, to: isOnWatch)
        }
        .eraseToAnyPublisher()
    }

    func updateLastPlayedDate(for episode: EpisodeDataModel.ID, date: Date) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode, keyPath: \.lastPlayed, to: date)
        }
        .eraseToAnyPublisher()
    }

    func updateLastPosition(_ lastPosition: Int?, for episode: EpisodeDataModel.ID) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode, keyPath: \.lastPosition, to: lastPosition)
        }
        .eraseToAnyPublisher()
    }
    
    func updateDuration(_ duration: Int, for episode: EpisodeDataModel.ID) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode, keyPath: \.duration, to: duration)
        }
        .eraseToAnyPublisher()
    }
    
    func updateEpisode(_ episode: EpisodeDataModel.ID, isDownloaded: Bool) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode, keyPath: \.isDownloaded, to: isDownloaded)
        }
        .eraseToAnyPublisher()
    }
    
    func updateNumberOfPlays(_ episode: EpisodeDataModel.ID, numberOfPlays: Int) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode, keyPath: \.numberOfPlays, to: numberOfPlays)
        }
        .eraseToAnyPublisher()
    }
    
    func incrementNumberOfPlays(of episode: EpisodeDataModel.ID) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {

            guard let model = await self.getEpisodeDataModel(episode) else { return }
            try await self.contextManager.transaction {
                model.numberOfPlays += 1
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAll() -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            let predicate = #Predicate<EpisodeDataModel> { _ in true }
            try await self.contextManager.delete(where: predicate)
        }
        .eraseToAnyPublisher()
    }
    
    func deleteEpisode(with id: String) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            let predicate = #Predicate<EpisodeDataModel> { $0.id == id }
            try await self.contextManager.delete(where: predicate)
        }
        .eraseToAnyPublisher()
    }
    
    func deleteEpisode(_ episode: EpisodeDataModel) -> AnyPublisher<Void, Error> {
        deleteEpisode(with: episode.id)
    }
    
    func resetDownloadEpisodes() -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            let descriptor = FetchDescriptor<EpisodeDataModel>(
                predicate: #Predicate<EpisodeDataModel> { $0.isDownloaded == true }
            )
            let models = try await self.contextManager.fetch(descriptor)
            try await self.contextManager.transaction {
                models.forEach { model in
                    model.isDownloaded = false
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getPodcasts() -> AnyPublisher<[PodcastDataModel], Error> {
        let descriptor = FetchDescriptor<PodcastDataModel>()
        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .eraseToAnyPublisher()
    }

    func getPodcast(id: PodcastDataModel.ID) -> AnyPublisher<PodcastDataModel?, any Error> {
        var descriptor = FetchDescriptor<PodcastDataModel>(
            predicate: #Predicate<PodcastDataModel> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .map { $0.first }
            .eraseToAnyPublisher()
    }

    func insertPodcasts(_ podcasts: [PodcastDataModel]) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.contextManager.insert(podcasts, ignoreIfExists: false)
        }
        .eraseToAnyPublisher()
    }

    func deletePodcast(_ podcast: PodcastDataModel.ID) -> AnyPublisher<Void, any Error> {
        ThrowingAsyncPublisher {
            let predicate = #Predicate<PodcastDataModel>{ $0.id == podcast }
            try await self.contextManager.delete(where: predicate)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension SwiftDataDatabase {
    private func getEpisodeDataModel(_ id: String) async -> EpisodeDataModel? {
        var descriptor = FetchDescriptor<EpisodeDataModel>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? await contextManager.fetch(descriptor).first
    }

    private func updateEpisodeDataModel<Value>(of id: String, keyPath: WritableKeyPath<EpisodeDataModel, Value>, to value: Value) async throws {
        guard var model = await getEpisodeDataModel(id) else { return }
        try await contextManager.transaction {
            model[keyPath: keyPath] = value
        }
    }
}

