//
//  RatingData.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 23..
//

import Foundation

struct RatingData {

    // MARK: Properties

    let episodeID: String
    let publishDate: Date
    let isFavorite: Bool
    let numberOfPlays: Int
    let lastPlayedDate: Date?
    var rating: Double = .zero

    // MARK: Init

    init(episode: EpisodeData) {
        self.episodeID = episode.id
        self.publishDate = episode.publishDate
        self.isFavorite = episode.isFavourite
        self.numberOfPlays = episode.numberOfPlays
        self.lastPlayedDate = episode.lastPlayed
    }
}

// MARK: - Array extension

extension Array where Element == RatingData {

    // MARK: Constants

    private enum Constant {
        static let playedRating: Double = 3
        static let favoriteCoefficient: Double = 2.5
        static let maxNumberOfPlaysThreshold = 2
        static let playedManyCoefficient: Double = 5
        static let dateFromNewThresholCoefficient: Double = 0.9
        static let relativeNewestRelevantAdditionalValue: Double = 2.4
    }

    // MARK: Public methods

    mutating func calculateRatings() {
        setRatingsByLastPlayedDateAndFavorite()
        setRatingsByPlayedMany()
    }

    // MARK: Helpers

    private mutating func setRatingsByLastPlayedDateAndFavorite() {
        for index in indices {
            guard self[index].lastPlayedDate != nil || self[index].numberOfPlays > .zero else { continue }

            self[index].rating = Constant.playedRating

            if self[index].isFavorite {
                self[index].rating *= Constant.favoriteCoefficient
            }
        }
    }

    private mutating func setRatingsByPlayedMany() {
        let maxNumberOfPlays = self.max(by: { $0.numberOfPlays < $1.numberOfPlays })?.numberOfPlays ?? .zero

        guard maxNumberOfPlays >= Constant.maxNumberOfPlaysThreshold else { return }

        for index in indices {
            let add = Double(self[index].numberOfPlays) / Double(maxNumberOfPlays) * Constant.playedManyCoefficient
            self[index].rating += add
        }
    }
}
