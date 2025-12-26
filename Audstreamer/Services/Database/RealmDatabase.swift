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
    func insertEpisodes(_ episodes: [Episode], overwrite: Bool) -> AnyPublisher<Void, Error> {
        let episodes = mapEpisodes(episodes)
        return write { realm in
            let insert = overwrite ? episodes : episodes.filter { !self.getAllEpisodes().map(\.id).contains($0.id) }
            realm.add(insert, update: .all)
        }
        .subscribe(on: Constant.defaultQueue)
        .eraseToAnyPublisher()
    }

    func getEpisodes(filterFavorites: Bool,
                     filterDownloads: Bool,
                     filterWatch: Bool,
                     keyword: String?) -> AnyPublisher<[Episode], Error> {
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
            .map { [unowned self] in mapEpisodes($0) }
            .eraseToAnyPublisher()
    }

    func updateEpisode(_ episode: Episode, isFavorite: Bool) -> AnyPublisher<Void, Error> {
        getEpisodeData(id: episode.id)
            .first()
            .flatMap { [unowned self] episode in
                write { _ in episode?.isFavourite = isFavorite }
            }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func updateEpisode(_ episode: Episode, isOnWatch: Bool) -> AnyPublisher<Void, Error> {
        getEpisodeData(id: episode.id)
            .first()
            .flatMap { [unowned self] episode in
                write { _ in episode?.isOnWatch = isOnWatch }
            }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func updateEpisode(_ episode: Episode, isDownloaded: Bool) -> AnyPublisher<Void, Error> {
        getEpisodeData(id: episode.id)
            .first()
            .flatMap { [unowned self] episode in
                write { _ in episode?.isDownloaded = isDownloaded }
            }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func updateLastPosition(_ lastPosition: Int?, for episode: Episode) -> AnyPublisher<Void, Error> {
        getEpisodeData(id: episode.id)
            .first()
            .flatMap { [unowned self] episode in
                write { _ in episode?.lastPosition = lastPosition ?? -1 }
            }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func updateLastPlayedDate(for episode: Episode) -> AnyPublisher<Void, Error> {
        updateLastPlayedDate(for: episode, date: Date())
    }

    func updateNumberOfPlays(_ episode: Episode, numberOfPlays: Int) -> AnyPublisher<Void, Error> {
        getEpisodeData(id: episode.id)
            .first()
            .flatMap { [unowned self] episode in
                write { _ in episode?.numberOfPlays = numberOfPlays }
            }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func incrementNumberOfPlays(of episode: Episode) -> AnyPublisher<Void, Error> {
        getEpisodeData(id: episode.id)
            .first()
            .flatMap { [unowned self] episode in
                write { _ in episode?.numberOfPlays += 1 }
            }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func getLastPlayedEpisode() -> AnyPublisher<Episode?, Error> {
        makeInstanceOnRightThread()
            .flatMap { realm in
                let emitter = realm.objects(EpisodeData.self)
                    .filter("lastPlayed != nil")
                    .sorted(byKeyPath: "lastPlayed", ascending: false)
                return RealmPublishers.array(from: emitter).map { $0.first }
            }
            .map { [unowned self] episode in
                guard let episode else { return nil }
                return mapEpisode(from: episode)
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

    func updateDuration(_ duration: Int, for episode: Episode) -> AnyPublisher<Void, Error> {
        getEpisodeData(id: episode.id)
            .first()
            .flatMap { [unowned self] episode in
                write { _ in episode?.duration = duration }
            }
            .subscribe(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func getEpisode(id: String) -> AnyPublisher<Episode?, Error> {
        getEpisodeData(id: id)
            .map { [unowned self] episode in
                guard let episode else { return nil }
                return mapEpisode(from: episode)
            }
            .eraseToAnyPublisher()
    }

    func updateLastPlayedDate(for episode: Episode, date: Date) -> AnyPublisher<Void, Error> {
        getEpisodeData(id: episode.id)
            .flatMap { [unowned self] episode in
                write { _ in episode?.lastPlayed = date }
            }
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

    func deleteEpisode(_ episode: Episode) -> AnyPublisher<Void, Error> {
        getEpisodeData(id: episode.id)
            .flatMap { [unowned self] episode in
                guard let episode else { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
                return write { $0.delete(episode) }
            }
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
        makeInstanceOnRightThread()
            .flatMap { realm in
                Promise<Void, Error> { promise in
                    do {
                        try realm.write {
                            block(realm)
                            promise(.success(()))
                        }
                    } catch {
                        promise(.failure(error))
                    }
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
            .receive(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func getEpisodeData(id: String) -> AnyPublisher<EpisodeData?, Error> {
        makeInstanceOnRightThread()
            .flatMap { realm in
                let emitter = realm.objects(EpisodeData.self).filter("id == %@", id)
                return RealmPublishers.array(from: emitter).map { $0.first }
            }
            .eraseToAnyPublisher()
    }

    private func mapEpisode(from episode: Episode) -> EpisodeData {
        let data = EpisodeData()

        data.id = episode.id
        data.title = episode.title
        data.publishDate = episode.publishDate
        data.descriptionText = episode.descriptionText ?? ""
        data.mediaURL = episode.mediaURL.absoluteString
        data.image = episode.image?.absoluteString
        data.thumbnail = episode.thumbnail?.absoluteString
        data.link = episode.link?.absoluteString
        data.duration = episode.duration
        data.isFavourite = episode.isFavourite
        data.lastPosition = episode.lastPosition ?? -1
        data.lastPlayed = episode.lastPlayed
        data.isDownloaded = episode.isDownloaded
        data.numberOfPlays = episode.numberOfPlays
        data.isOnWatch = episode.isOnWatch

        return data
    }

    private func mapEpisodes(_ episodes: [Episode]) -> [EpisodeData] {
        episodes.map { mapEpisode(from: $0) }
    }

    private func mapEpisode(from data: EpisodeData) -> Episode? {
        guard let mediaURLString = data.mediaURL,
              let mediaURL = URL(string: mediaURLString) else { return nil }
        return Episode(
            id: data.id,
            title: data.title,
            publishDate: data.publishDate,
            descriptionText: data.descriptionText,
            mediaURL: mediaURL,
            image: URL(string: data.image ?? ""),
            thumbnail: URL(string: data.thumbnail ?? ""),
            link: URL(string: data.link ?? ""),
            duration: data.duration,
            isFavourite: data.isFavourite,
            lastPosition: data.lastPosition,
            lastPlayed: data.lastPlayed,
            isDownloaded: data.isDownloaded,
            numberOfPlays: data.numberOfPlays,
            isOnWatch: data.isOnWatch
        )
    }

    private func mapEpisodes(_ episodes: [EpisodeData]) -> [Episode] {
        episodes.compactMap { mapEpisode(from: $0) }
    }
}
