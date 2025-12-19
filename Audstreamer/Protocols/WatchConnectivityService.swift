//
//  WatchConnectivityService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import Combine

protocol WatchConnectivityService {
    func startUpdating()
    func stopUpdating()
    func isAvailable() -> AnyPublisher<Bool, Error>
    func isConnected() -> AnyPublisher<Bool, Error>
    func getAggregatedFileTransferProgress() -> AnyPublisher<FileTransferAggregatedProgress, Error>
    func transferEpisode(_ episodeID: String) -> AnyPublisher<Void, Error>
    func cancelFileTransferForEpisode(_ episodeID: String) -> AnyPublisher<Void, Error>
}
