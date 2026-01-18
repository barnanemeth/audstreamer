//
//  EpisodeSection.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation

import Domain

struct EpisodeSection: Identifiable, Hashable, Equatable {

    // MARK: Properties

    let episode: Episode
    let isOpened: Bool
    let title: String?
    let isDownloaded: Bool
    let isWatchAvailable: Bool

    var id: String { episode.id }
}

// MARK: - Hashable & Equatable

extension EpisodeSection {
    func hash(into hasher: inout Hasher) {
        hasher.combine(episode.id)
        hasher.combine(episode.isFavourite)
        hasher.combine(episode.isDownloaded)
        hasher.combine(episode.isOnWatch)
        hasher.combine(isDownloaded)
        hasher.combine(isOpened)
    }

    static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.episode.id == rhs.episode.id &&
        lhs.episode.isFavourite == rhs.episode.isFavourite &&
        lhs.episode.isDownloaded == rhs.episode.isDownloaded &&
        lhs.episode.isOnWatch == rhs.episode.isOnWatch &&
        lhs.episode.duration == rhs.episode.duration &&
        lhs.isDownloaded == rhs.isDownloaded &&
        lhs.isOpened == rhs.isOpened
    }
}
