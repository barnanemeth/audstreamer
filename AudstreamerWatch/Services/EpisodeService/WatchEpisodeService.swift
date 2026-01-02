//
//  WatchEpisodeService.swift
//  AudstreamerWatch Watch App
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

//import Foundation
//import Combine
//import WatchConnectivity
//
//final class WatchEpisodeService: NSObject {
//
//    // MARK: Constants
//
//    enum Constant {
//        static let episodesMessageKey = "episodes"
//        static let lastPlayedDateMessageKey = "lastPlayedDate"
//        static let lastPositionMessageKey = "lastPosition"
//        static let episodesUserDefaultsKey = "Episodes"
//        static let episodeIDMessageKey = "episodeID"
//    }
//
//    // MARK: Properties
//
//    var cancellables = Set<AnyCancellable>()
//    let session = WCSession.default
//    let userDefaults = UserDefaults.standard
//    let encoder = JSONEncoder()
//    let decoder = JSONDecoder()
//    let fileManager = FileManager.default
//    let updateTriggerSubject = PassthroughSubject<Void, Never>()
//    lazy var episodes: AnyPublisher<[EpisodeCommon], Error> = {
//        Publishers.CombineLatest(userDefaults.publisher(for: \.episodesData), updateTriggerSubject.prepend(()))
//            .setFailureType(to: Error.self)
//            .map(\.0)
//            .tryMap { [unowned self] in try decodeEpisodes(from: $0) }
//            .flatMap { [unowned self] episodes -> AnyPublisher<([EpisodeCommon], [Bool]), Error> in
//                let episodesPublishers = Just(episodes).setFailureType(to: Error.self)
//                let downloadStates: AnyPublisher<[Bool], Error> = if !episodes.isEmpty {
//                    episodes.map { isDownloaded($0) }.zip()
//                } else {
//                    Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
//                }
//
//                return Publishers.Zip(episodesPublishers, downloadStates).eraseToAnyPublisher()
//            }
//            .map { episodes, downloadStates in
//                zip(episodes, downloadStates).map { episode, isDownloaded in
//                    var episode = episode
//                    episode.isDownloaded = isDownloaded
//                    return episode
//                }
//            }
//            .shareReplay()
//    }()
//
//    // MARK: Init
//
//    override init() {
//        super.init()
//
//        setupSession()
//        createEpisodesFolderIfNeeded()
//    }
//}
