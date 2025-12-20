//
//  WatchURLHelper.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 02/11/2023.
//

import Foundation

enum WatchURLHelper {
    static var episodeDirectory: URL? {
        FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appending(path: "episodes", directoryHint: .isDirectory)
    }

    static func getURLForEpisode(_ episodeID: String) -> URL? {
        episodeDirectory?.appendingPathComponent(episodeID, conformingTo: .mp3)
    }
}
