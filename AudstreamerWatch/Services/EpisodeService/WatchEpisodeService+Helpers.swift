//
//  WatchEpisodeService+Helpers.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 14..
//

import Foundation
import Combine

import Common
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
        Just(isEpisodeDownloaded(episode))
            .tryMap { [unowned self] _ in try delete(episode) }
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

    func isEpisodeDownloaded(_ episode: Episode) -> Bool {
        guard let url = WatchURLHelper.getURLForEpisode(episode.id) else {
            return false
        }
        return fileManager.fileExists(atPath: url.path)
    }

    func delete(_ episode: Episode) throws {
        guard let url = WatchURLHelper.getURLForEpisode(episode.id) else { return }
        try fileManager.removeItem(at: url)
    }

    func subscribeToCurrentPlayingAudioInfo() {
        currentlyPalayingEpispde
            .unwrap()
            .removeDuplicates()
            .flatMap { [unowned self] episode -> AnyPublisher<Void, Error> in
                let updateNowPlaying = remotePlayer.updateNowPlaying(episode, preferredDuration: episode.duration)
                let updateLastPlayedDate = updateLastPlayedDate(.now, for: episode)

                return Publishers.Zip(updateNowPlaying, updateLastPlayedDate).toVoid()
            }
            .sink()
            .store(in: &cancellables)
    }

    func subscribeToCurrentSeconds() {
        Publishers.CombineLatest(audioPlayer.getCurrentSeconds(), currentlyPalayingEpispde)
            .throttle(for: 30, scheduler: DispatchQueue.global(qos: .background), latest: true)
            .flatMap { [unowned self] seconds, episode -> AnyPublisher<Void, Error> in
                guard let episode, !seconds.isNaN else { return Just.void() }

                let updateNowPlaying = remotePlayer.updateElapsedTime(seconds)
                let updateLastPosition = updateLastPosition(Int(seconds), for: episode)

                return Publishers.Zip(updateNowPlaying, updateLastPosition).toVoid()
            }
            .sink()
            .store(in: &cancellables)

        audioPlayer.getCurrentSeconds()
            .flatMap { [unowned self] in self.remotePlayer.updateElapsedTime($0) }
            .sink()
            .store(in: &cancellables)
    }

    func subscribeToRemotePlayerEvents() {
        remotePlayer.getEvents()
            .flatMap { [unowned self] remoteEvent in
                switch remoteEvent {
                case .play: return self.audioPlayer.play()
                case .pause: return self.audioPlayer.pause()
                case .skipForward, .seekForward, .nextTrack: return  self.audioPlayer.seekForward()
                case .skipBackward, .seekBackward, .previousTrack: return self.audioPlayer.seekBackward()
                case let .changePlaybackPosition(position): return self.audioPlayer.seek(to: position)
                default: return Just.void()
                }
            }
            .sink()
            .store(in: &cancellables)
    }

    func deleteAbandonedEpisodes() -> AnyPublisher<Void, Error> {
        Promise { promise in
            DispatchQueue.global(qos: .background).async {
                do {
                    let episodes = try self.decodeEpisodes(from: self.userDefaults.episodesData)
                    let downloadedEpisodes = self.urlsForDownloadedEpisodes()

                    try downloadedEpisodes.forEach { episodeURL in
                        let episodeID = episodeURL.deletingPathExtension().lastPathComponent
                        guard !episodes.contains(where: { $0.id == episodeID }) else { return }
                        try self.fileManager.removeItem(at: episodeURL)

                        promise(.success(()))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
