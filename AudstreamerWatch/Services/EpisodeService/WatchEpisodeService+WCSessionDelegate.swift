//
//  WatchEpisodeService+WCSessionDelegate.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 07/11/2023.
//

import Foundation
import WatchConnectivity

// MARK: - WCSessionDelegate methods

extension WatchEpisodeService: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) { }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let episodes = mapEpisodes(from: applicationContext[Constant.episodesMessageKey] as? [[String: Any]])
        guard let episodeData = try? encoder.encode(episodes) else { return }
        userDefaults.episodesData = episodeData
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let filename = file.fileURL.lastPathComponent
        guard let episodeID = filename.components(separatedBy: ".").first,
              let targetURL = WatchURLHelper.getURLForEpisode(episodeID) else { return }
        do {
            try fileManager.moveItem(at: file.fileURL, to: targetURL)
            updateDownloadedState(of: episodeID, isDownloaded: true)
        } catch {
            print(error)
        }
    }
}
