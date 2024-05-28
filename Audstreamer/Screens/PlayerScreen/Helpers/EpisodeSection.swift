//
//  EpisodeSection.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation

struct EpisodeSection: Hashable, Equatable {

    // MARK: Enums

    enum EpisodeItem: Hashable, Equatable {
        case info(episode: EpisodeData, isFavorite: Bool, isDownloaded: Bool, isOnWatch: Bool)
        // swiftlint:disable:next enum_case_associated_values_count
        case detail(
            episode: EpisodeData,
            isFavorite: Bool,
            duration: Int,
            isDownloaded: Bool,
            isOnWatch: Bool,
            isWatchAvailable: Bool
        )
    }

    // MARK: Properties

    let episode: EpisodeData
    let isOpened: Bool
    let title: String?
    let isDownloaded: Bool
    let isWatchAvailable: Bool

    var episodeID: String { episode.id }
    var items: [EpisodeItem] {
        var items: [EpisodeItem] = [
            .info(
                episode: episode,
                isFavorite: episode.isFavourite,
                isDownloaded: episode.isDownloaded,
                isOnWatch: episode.isOnWatch
            )
        ]
        if isOpened {
            let detail = EpisodeItem.detail(
                episode: episode,
                isFavorite: episode.isFavourite,
                duration: episode.duration,
                isDownloaded: episode.isDownloaded,
                isOnWatch: episode.isOnWatch,
                isWatchAvailable: isWatchAvailable
            )
            items.append(detail)
        }
        return items
    }
}

// MARK: - Hashable & Equatable

extension EpisodeSection {
    func hash(into hasher: inout Hasher) {
        hasher.combine(episode.id)
        hasher.combine(isDownloaded)
    }

    static func == (_ lhs: EpisodeSection, _ rhs: EpisodeSection) -> Bool {
        lhs.episode.id == rhs.episode.id && lhs.isDownloaded == rhs.isDownloaded
    }
}
