//
//  WatchEpisodeService+Helpers.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 14..
//

import Foundation
import Combine

import Domain

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

    func mapEpisodes(from dictionaryArray: [[String: Any]]?) -> [Episode] {
        guard let dictionaryArray else { return [] }
        return dictionaryArray.compactMap { Episode(from: $0) }
    }

    func decodeEpisodes(from data: Data?) throws -> [Episode] {
        guard let data else { return [] }
        return try decoder.decode([Episode].self, from: data)
    }

    func deleteEpisodeIfNeeded(_ episode: Episode) -> AnyPublisher<Void, Error> {
        isDownloaded(episode)
            .flatMap { [unowned self] _ in self.delete(episode) }
            .replaceError(with: ())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

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

    func urlsForDownloadedEpisodes() -> [URL] {
        guard let directoryURL = WatchURLHelper.episodeDirectory else { return [] }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension.lowercased() == "mp3" }
        } catch {
            return []
        }
    }

    func createEpisodesFolderIfNeeded() {
        guard let directoryURL = WatchURLHelper.episodeDirectory else { return }

        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)
        if !exists || !isDirectory.boolValue {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}
