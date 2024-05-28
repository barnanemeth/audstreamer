//
//  Cloud.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 16..
//

import Foundation
import Combine

protocol Cloud {
    func getFavoriteEpisodeIDs() -> AnyPublisher<[String], Error>
    func setFavorite(_ isFavorite: Bool, for episodeID: String) -> AnyPublisher<Void, Error>
    func getLastPlayedDates() -> AnyPublisher<[String: Date], Error>
    func setLastPlayedDate(_ lastPlayedDate: Date, for episodeID: String) -> AnyPublisher<Void, Error>
    func getLastPositions() -> AnyPublisher<[String: Int], Error>
    func setLastPosition(_ lastPosition: Int, for episodeID: String) -> AnyPublisher<Void, Error>
    func getNumberOfPlays() -> AnyPublisher<[String: Int], Error>
    func setNumberOfPlays(_ numberOfPlays: Int, for episodeID: String) -> AnyPublisher<Void, Error>
    func getUserRatings() -> AnyPublisher<[UserRating], Error>
    func synchronizePrivateData() -> AnyPublisher<Void, Error>
    func synchronizePublicData() -> AnyPublisher<Void, Error>
    func resetPrivateData() -> AnyPublisher<Void, Error>
    func resetPublicData() -> AnyPublisher<Void, Error>
    func updateFromLocal() -> AnyPublisher<Void, Error>
}

enum CloudError: Error, LocalizedError {
    case generalError(Error)
    case unavailableAccount

    var errorDescription: String? {
        switch self {
        case let .generalError(error): return error.localizedDescription
        case .unavailableAccount: return L10n.appleIDRequired
        }
    }
}
