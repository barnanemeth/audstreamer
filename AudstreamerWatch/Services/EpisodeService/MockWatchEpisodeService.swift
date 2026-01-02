//
//  MockEpisodeService.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 17..
//

//import Foundation
//import Combine
//
//struct MockWatchEpisodeService { }
//
//// MARK: - EpisodeService
//
//extension MockWatchEpisodeService: EpisodeService {
//    func getEpisodes() -> AnyPublisher<[EpisodeCommon], any Error> {
//        let episodes = (0..<100).compactMap { offset in
//            var episode = EpisodeCommon(
//                from: [
//                    "id": "id\(offset)",
//                    "title": "Title\(offset) title title title title title title",
//                    "duration": 60,
//                    "lastPosition": 0
//                ]
//            )
//            episode?.isDownloaded = false
//            return episode
//        }
//
//        return Just(episodes).setFailureType(to: Error.self).eraseToAnyPublisher()
//    }
//
//    func updateLastPlayedDate(_ lastPlayedDate: Date, for episodeID: String) -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func updateLastPosition(_ lastPosition: Int, for episodeID: String) -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func deleteAbandonedEpisodes() -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func sendUpdateTrigger() -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//}
//
//// MARK: - DownloadService
//
//extension MockWatchEpisodeService: DownloadService {
//    func delete(_ item: any Downloadable) -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func getEvent() -> AnyPublisher<DownloadEvent, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func getAggregatedEvent() -> AnyPublisher<DownloadAggregatedEvent, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func getDownloadSize() -> AnyPublisher<Int, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func refreshDownloadSize() -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func deleteDownloads() -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func pause(_ item: any Downloadable) -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func resume(_ item: any Downloadable) -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func cancel(_ item: any Downloadable) -> AnyPublisher<Void, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//
//    func isDownloaded(_ item: any Downloadable) -> AnyPublisher<Bool, any Error> {
//        Empty(completeImmediately: false).eraseToAnyPublisher()
//    }
//}
