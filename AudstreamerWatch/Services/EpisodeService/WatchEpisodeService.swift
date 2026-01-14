//
//  WatchEpisodeService.swift
//  AudstreamerWatch Watch App
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import Foundation
import Combine
import WatchConnectivity

import Common
import Domain

final class WatchEpisodeService: NSObject {

    // MARK: Constants

    enum Constant {
        static let episodesMessageKey = "episodes"
        static let lastPlayedDateMessageKey = "lastPlayedDate"
        static let lastPositionMessageKey = "lastPosition"
        static let episodesUserDefaultsKey = "Episodes"
        static let episodeIDMessageKey = "episodeID"
    }

    @Injected var audioPlayer: AudioPlayer
    @Injected var remotePlayer: RemotePlayer

    // MARK: Properties

    var cancellables = Set<AnyCancellable>()
    let session = WCSession.default
    let userDefaults = UserDefaults.standard
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let fileManager = FileManager.default
    let updateTriggerSubject = PassthroughSubject<Void, Never>()
    lazy var episodes: AnyPublisher<[Episode], Error> = {
        Publishers.CombineLatest(userDefaults.publisher(for: \.episodesData), updateTriggerSubject.prepend(()))
            .setFailureType(to: Error.self)
            .map(\.0)
            .tryMap { [unowned self] in try decodeEpisodes(from: $0) }
            .map { [unowned self] episodes in
                episodes.map { episode in
                    var episode = episode
                    episode.isDownloaded = isEpisodeDownloaded(episode)
                    return episode
                }
            }
            .shareReplay()
    }()
    var currentlyPalayingEpispde: AnyPublisher<Episode?, Error> {
        audioPlayer.getCurrentPlayingAudioInfo()
            .flatMapLatest { [unowned self] audioInfo -> AnyPublisher<Episode?, Error> in
                guard let audioInfo else { return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher() }
                return episode(id: audioInfo.id)
                    .map { episode in
                        guard var episode else { return nil }
                        episode.duration = audioInfo.duration
                        return episode
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: Init

    override init() {
        super.init()

        setupSession()
        createEpisodesFolderIfNeeded()
    }
}
