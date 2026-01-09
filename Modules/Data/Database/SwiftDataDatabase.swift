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
            let dataModels = self.mapEpisodes(episodes)
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
            .map { [unowned self] in mapEpisodes($0) }
            .eraseToAnyPublisher()
    }

    func getEpisode(id: String) -> AnyPublisher<Episode?, Error> {
        let targetId = id
        var descriptor = FetchDescriptor<EpisodeDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .map { [unowned self] in mapEpisode(from: $0.first) }
            .eraseToAnyPublisher()
    }
    
    func getLastEpisodePublishDate() -> AnyPublisher<Date?, Error> {
        var descriptor = FetchDescriptor<EpisodeDataModel>(
            sortBy: [.init(\.publishDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .map { [unowned self] in mapEpisode(from: $0.first)?.publishDate }
            .eraseToAnyPublisher()
    }
    
    func getLastPlayedEpisode() -> AnyPublisher<Episode?, Error> {
        var descriptor = FetchDescriptor<EpisodeDataModel>(
            sortBy: [.init(\.lastPlayed, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return ModelContextFetchPublisher(contextManager: contextManager, descriptor: descriptor)
            .map { [unowned self] in mapEpisode(from: $0.first) }
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
            model.numberOfPlays += 1
            try await self.contextManager.save()
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
            models.forEach { model in
                model.isDownloaded = false
            }
            try await self.contextManager.save()
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
        model[keyPath: keyPath] = value
        try await contextManager.save()
    }

    private func mapEpisode(from episode: Episode?) -> EpisodeDataModel? {
        guard let episode else { return nil }
        return EpisodeDataModel(
            id: episode.id,
            title: episode.title,
            publishDate: episode.publishDate,
            descriptionText: episode.descriptionText,
            mediaURL: episode.mediaURL,
            image: episode.image,
            thumbnail: episode.thumbnail,
            link: episode.link,
            duration: episode.duration,
            isFavourite: episode.isFavourite,
            lastPosition: episode.lastPosition,
            lastPlayed: episode.lastPlayed,
            isDownloaded: episode.isDownloaded,
            numberOfPlays: episode.numberOfPlays,
            isOnWatch: episode.isOnWatch
        )
    }

    private func mapEpisodes(_ episodes: [Episode]) -> [EpisodeDataModel] {
        episodes.compactMap { mapEpisode(from: $0) }
    }

    private func mapEpisode(from data: EpisodeDataModel?) -> Episode? {
        guard let data else { return nil }
        return Episode(
            id: data.id,
            title: data.title,
            publishDate: data.publishDate,
            descriptionText: data.descriptionText,
            mediaURL: data.mediaURL,
            image: data.image,
            thumbnail: data.thumbnail,
            link: data.link,
            duration: data.duration ?? .zero,
            isFavourite: data.isFavourite,
            lastPosition: data.lastPosition,
            lastPlayed: data.lastPlayed,
            isDownloaded: data.isDownloaded,
            numberOfPlays: data.numberOfPlays,
            isOnWatch: data.isOnWatch
        )
    }

    private func mapEpisodes(_ episodes: [EpisodeDataModel]) -> [Episode] {
        episodes.compactMap { mapEpisode(from: $0) }
    }
}

