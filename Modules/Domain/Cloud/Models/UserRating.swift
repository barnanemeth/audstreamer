//
//  UserRating.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 12. 09..
//

import Foundation

public struct UserRating {

    // MARK: Properties

    public let userID: String
    public let episodeID: String
    public let rating: Double

    // MARK: Init

    public init(userID: String, episodeID: String, rating: Double) {
        self.userID = userID
        self.episodeID = episodeID
        self.rating = rating
    }
}
