//
//  WatchURLHelper.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 02/11/2023.
//

import Foundation

enum WatchURLHelper {
    static func getURLForEpisode(_ episodeID: String) -> URL? {
        FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(episodeID, conformingTo: .mp3)
    }
}
