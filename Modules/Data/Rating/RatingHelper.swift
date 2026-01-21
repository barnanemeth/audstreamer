//
//  RatingHelper.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 26..
//

import Foundation
import Combine

import Common
import Domain

enum RatingHelper {

    // MARK: Constants

    private enum Constant {
        static let calculationQueue = DispatchQueue.global(qos: .background)
    }
}

// MARK: - Public methods

extension RatingHelper {
    static func getEpisodeRatings() -> AnyPublisher<[RatingData], Error> {
        @Injected var database: Database
        @Injected var contextManager: SwiftDataContextManager

        return database.getEpisodes(filterFavorites: false, filterDownloads: false, filterWatch: false, keyword: nil)
            .asyncTryMap { await contextManager.mapDataModels($0) }
            .first()
            .map { $0.map { RatingData(episode: $0) } }
            .flatMap { calculateRatings(for: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension RatingHelper {
    private static func calculateRatings(for ratingDatas: [RatingData]) -> AnyPublisher<[RatingData], Error> {
        Promise<[RatingData], Error> { promise in
            Constant.calculationQueue.async {
                var ratingDatas = ratingDatas
                ratingDatas.calculateRatings()

                promise(.success(ratingDatas))
            }
        }
        .eraseToAnyPublisher()
    }
}
