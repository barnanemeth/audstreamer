//
//  WatchEpisodeService.swift
//  AudstreamerWatch Watch App
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import Foundation
import Combine
import WatchConnectivity

final class WatchEpisodeService: NSObject {

    // MARK: Constants

    enum Constant {
        static let episodesMessageKey = "episodes"
        static let lastPlayedDateMessageKey = "lastPlayedDate"
        static let lastPositionMessageKey = "lastPosition"
        static let episodesUserDefaultsKey = "Episodes"
        static let episodeIDMessageKey = "episodeID"
    }

    // MARK: Properties

    var cancellables = Set<AnyCancellable>()
    let session = WCSession.default
    let userDefaults = UserDefaults.standard
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let fileManager = FileManager.default
    lazy var episodes: AnyPublisher<[EpisodeCommon], Error> = {
        userDefaults.publisher(for: \.episodesData)
            .setFailureType(to: Error.self)
            .tryMap { [unowned self] in try self.decodeEpisodes(from: $0) }
            .flatMap { [unowned self] episodes -> AnyPublisher<([EpisodeCommon], [Bool]), Error> in
                let episodesPublishers = Just(episodes).setFailureType(to: Error.self)
                let downloadStates = !episodes.isEmpty ?
                    episodes.map { self.isDownloaded($0) }.zip() :
                    Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()

                return Publishers.Zip(episodesPublishers, downloadStates).eraseToAnyPublisher()
            }
            .map { episodes, downloadStates in
                zip(episodes, downloadStates).map { episode, isDownloaded in
                    var episode = episode
                    episode.isDownloaded = isDownloaded
                    return episode
                }
            }
            .shareReplay()
    }()

    // MARK: Init

    override init() {
        super.init()

        setupSession()
//        setpInitialEpisodeData()
        setupDeleteOrDownloadSubscription()
    }
}
