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
    func insertEpisodes(_ episodes: [Episode], overwrite: Bool) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            let dataModels = episodes.asDomainModels
            try await self.contextManager.insert(dataModels)
        }
        .eraseToAnyPublisher()
    }

    func getEpisodes(filterFavorites: Bool, filterDownloads: Bool, filterWatch: Bool, keyword: String?) -> AnyPublisher<[Episode], Error> {
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

        let combinedPredicate = predicates.disjunction()

        let descriptor = FetchDescriptor<EpisodeDataModel>(
            predicate: combinedPredicate,
            sortBy: [.init(\.publishDate, order: .reverse)]
        )

        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .eraseToAnyPublisher()
    }

    func getEpisode(id: String) -> AnyPublisher<Episode?, Error> {
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
    
    func getLastPlayedEpisode() -> AnyPublisher<Episode?, Error> {
        var descriptor = FetchDescriptor<EpisodeDataModel>(
            sortBy: [.init(\.lastPlayed, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .map { $0.first }
            .eraseToAnyPublisher()
    }
    
    func updateEpisode(_ episode: Episode, isFavorite: Bool) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode.id, keyPath: \.isFavourite, to: isFavorite)
        }
        .eraseToAnyPublisher()
    }
    
    func updateEpisode(_ episode: Episode, isOnWatch: Bool) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode.id, keyPath: \.isOnWatch, to: isOnWatch)
        }
        .eraseToAnyPublisher()
    }

    func updateLastPlayedDate(for episode: Episode, date: Date) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode.id, keyPath: \.lastPlayed, to: date)
        }
        .eraseToAnyPublisher()
    }

    func updateLastPosition(_ lastPosition: Int?, for episode: Episode) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode.id, keyPath: \.lastPosition, to: lastPosition)
        }
        .eraseToAnyPublisher()
    }
    
    func updateDuration(_ duration: Int, for episode: Episode) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode.id, keyPath: \.duration, to: duration)
        }
        .eraseToAnyPublisher()
    }
    
    func updateEpisode(_ episode: Episode, isDownloaded: Bool) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode.id, keyPath: \.isDownloaded, to: isDownloaded)
        }
        .eraseToAnyPublisher()
    }
    
    func updateNumberOfPlays(_ episode: Episode, numberOfPlays: Int) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.updateEpisodeDataModel(of: episode.id, keyPath: \.numberOfPlays, to: numberOfPlays)
        }
        .eraseToAnyPublisher()
    }
    
    func incrementNumberOfPlays(of episode: Episode) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {

            guard let model = await self.getEpisodeDataModel(episode.id) else { return }
            try await self.contextManager.transaction {
                model.numberOfPlays += 1
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteDuplicates() -> AnyPublisher<Void, Error> {
        // TODO: necessary?!
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
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
    
    func deleteEpisode(_ episode: Episode) -> AnyPublisher<Void, Error> {
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

    func insertPodcasts(_ podcasts: [Podcast]) -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            let dataModels = podcasts.asDomainModels
            try await self.contextManager.insert(dataModels)
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

