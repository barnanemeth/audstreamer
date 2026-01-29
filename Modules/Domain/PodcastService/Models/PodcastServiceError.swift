//
//  PodcastServiceError.swift
//  Domain
//
//  Created by Barna Nemeth on 2026. 01. 29..
//

import Foundation

public enum PodcastServiceError: Error {
    case cannotDecodeFeed
    case cannotFindPodcast
    case alreadyExists
}
