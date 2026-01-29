//
//  PodcastSortingPreference.swift
//  Domain
//
//  Created by Barna Nemeth on 2026. 01. 29..
//

import Foundation

public enum PodcastSortingPreference {
    case byLatestRelease
    case byLatestInteraction
    case byTitle(ascending: Bool)
}
