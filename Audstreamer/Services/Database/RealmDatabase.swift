//
//  RealmDatabase.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import Foundation
import Combine

import RealmSwift

final class RealmDatabase {

    // MARK: Constants

    private enum Constant {
        static let schemaVersion: UInt64 = 15
        static let defaultQueue = DispatchQueue.main
        static let observedKeyPaths = ["id", "isFavourite", "duration", "isDownloaded", "isOnWatch"]
    }

    // MARK: Private properties

    private let realm: Realm

    // MARK: Init

    init() {
        do {
            let config = Realm.Configuration(schemaVersion: Constant.schemaVersion)
            realm = try Realm(configuration: config)
        } catch {
            preconditionFailure("Cannot initialize Realm instance, \(error)")
        }
    }
}

// MARK: - Database

extension RealmDatabase: Database {
    func insertEpisodes(_ episodes: [EpisodeData], overwrite: Bool) -> AnyPublisher<Void, Error> {
        write { realm in
            let insert = overwrite ? episodes : episodes.filter { !self.getAllEpisodes().map(\.id).contains($0.id) }
            realm.add(insert, update: .all)
        }
        .subscribe(on: Constant.defaultQueue)
        .eraseToAnyPublisher()
    }

    func getEpisodes(filterFavorites: Bool,
                     filterDownloads: Bool,
                     filterWatch: Bool,
                     keyword: String?) -> AnyPublisher<[EpisodeData], Error> {
        var predicates = [NSPredicate]()

        if let keyword = keyword {
            let predicateString = "title CONTAINS[c] %@ OR descriptionText CONTAINS[c] %@"
            let predicate = NSPredicate(format: predicateString, keyword, keyword)
            predicates.append(predicate)
        }

        if filterFavorites {
            let predicateString = "isFavourite == %d"
            let predicate = NSPredicate(format: predicateString, true)
            predicates.append(predicate)
        }

        if filterDownloads {
            let predicateString = "isDownloaded == %d"
            let predicate = NSPredicate(format: predicateString, true)
            predicates.append(predicate)
        }

        if filterWatch {
            let predicateString = "isOnWatch == %d"
            let predicate = NSPredicate(format: predicateString, true)
            predicates.append(predicate)
        }

        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        return makeInstanceOnRightThread()
            .flatMap { realm in
                let emitter = realm
                    .objects(EpisodeData.self)
                    .filter(combinedPredicate)
                    .sorted(byKeyPath: "publishDate", ascending: false)
                return RealmPublishers.array(from: emitter, keyPaths: Constant.observedKeyPaths)
            }
            .eraseToAnyPublisher()
    }

    func updateEpisode(_ episode: EpisodeData, isFavorite: Bool) -> AnyPublisher<Void, Error> {
        write { _ in episode.isFavourite = isFavorite }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func updateEpisode(_ episode: EpisodeData, isOnWatch: Bool) -> AnyPublisher<Void, Error> {
        write { _ in episode.isOnWatch = isOnWatch }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func updateEpisode(_ episode: EpisodeData, isDownloaded: Bool) -> AnyPublisher<Void, Error> {
        write { _ in episode.isDownloaded = isDownloaded }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func updateLastPosition(_ lastPosition: Int?, for episode: EpisodeData) -> AnyPublisher<Void, Error> {
        write { _ in episode.lastPosition = lastPosition ?? -1 }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func updateLastPlayedDate(for episode: EpisodeData) -> AnyPublisher<Void, Error> {
        updateLastPlayedDate(for: episode, date: Date())
    }

    func updateNumberOfPlays(_ episode: EpisodeData, numberOfPlays: Int) -> AnyPublisher<Void, Error> {
        write { _ in episode.numberOfPlays = numberOfPlays }
    }

    func incrementNumberOfPlays(of episode: EpisodeData) -> AnyPublisher<Void, Error> {
        write { _ in episode.numberOfPlays += 1 }
    }

    func getLastPlayedEpisode() -> AnyPublisher<EpisodeData?, Error> {
        makeInstanceOnRightThread()
            .flatMap { realm in
                let emitter = realm.objects(EpisodeData.self)
                    .filter("lastPlayed != nil")
                    .sorted(byKeyPath: "lastPlayed", ascending: false)
                return RealmPublishers.array(from: emitter).map { $0.first }
            }
            .eraseToAnyPublisher()
    }

    func deleteDuplicates() -> AnyPublisher<Void, Error> {
        write { realm in
            let all = realm.objects(EpisodeData.self)
            let titles = all.reduce(into: [String: [EpisodeData]](), { titles, episode in
                if titles[episode.title] == nil {
                    titles[episode.title] = [episode]
                } else {
                    titles[episode.title]?.append(episode)
                }
            })

            let delete = titles.filter { $0.value.count > 1 }.compactMap { $0.value.first }
            realm.delete(delete)
        }
        .subscribe(on: Constant.defaultQueue)
        .eraseToAnyPublisher()
    }

    func deleteAll() -> AnyPublisher<Void, Error> {
        write { $0.deleteAll() }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func updateDuration(_ duration: Int, for episode: EpisodeData) -> AnyPublisher<Void, Error> {
        write { _ in episode.duration = duration }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func getEpisode(id: String) -> AnyPublisher<EpisodeData?, Error> {
        makeInstanceOnRightThread()
            .flatMap { realm in
                let emitter = realm.objects(EpisodeData.self).filter("id == %@", id)
                return RealmPublishers.array(from: emitter).map { $0.first }
            }
            .eraseToAnyPublisher()
    }

    func updateLastPlayedDate(for episode: EpisodeData, date: Date) -> AnyPublisher<Void, Error> {
        write { _ in episode.lastPlayed = date }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func getLastEpisodePublishDate() -> AnyPublisher<Date?, Error> {
        makeInstanceOnRightThread()
            .flatMap { realm in
                let emitter = realm.objects(EpisodeData.self).sorted(byKeyPath: "publishDate", ascending: false)
                return RealmPublishers.array(from: emitter).map { $0.first?.publishDate }
            }
            .eraseToAnyPublisher()
    }

    func deleteEpisode(with id: String) -> AnyPublisher<Void, Error> {
        write { realm in
            guard let episode = realm.objects(EpisodeData.self).filter("id == %@", id).first else { return }
            realm.delete(episode)
        }
        .subscribe(on: Constant.defaultQueue)
        .eraseToAnyPublisher()
    }

    func deleteEpisode(_ episode: EpisodeData) -> AnyPublisher<Void, Error> {
        write { $0.delete(episode) }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func resetDownloadEpisodes() -> AnyPublisher<Void, Error> {
        write { realm in
            let episodes = realm.objects(EpisodeData.self).filter("isDownloaded == TRUE")
            episodes.forEach { $0.isDownloaded = false }
        }
        .subscribe(on: Constant.defaultQueue)
        .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension RealmDatabase {
    private func write(block: @escaping (Realm) -> Void) -> AnyPublisher<Void, Error> {
        Promise<Void, Error> { promise in
            do {
                try self.realm.write {
                    block(self.realm)
                    promise(.success(()))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    private func getAllEpisodes() -> [EpisodeData] {
        return Array(realm.objects(EpisodeData.self).sorted(byKeyPath: "publishDate", ascending: false))
    }

    private func makeInstanceOnRightThread() -> AnyPublisher<Realm, Error> {
        Just(realm)
            .setFailureType(to: Error.self)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
