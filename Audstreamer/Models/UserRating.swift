//
//  UserRating.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 12. 09..
//

import Foundation
import CloudKit

struct UserRating {

    // MARK: Properties

    let userID: String
    let episodeID: String
    let rating: Double
}
