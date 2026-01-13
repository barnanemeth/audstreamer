//
//  DownloadService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 04..
//

import Foundation
import Combine

import Domain

protocol DownloadService {
    func download(_ item: Downloadable, userInfo: [String: Any]) -> AnyPublisher<Void, Error>
    func delete(_ item: Downloadable) -> AnyPublisher<Void, Error>
    func getEvent() -> AnyPublisher<DownloadEvent, Error>
    func getAggregatedEvent() -> AnyPublisher<DownloadAggregatedEvent, Error>
    func getDownloadSize() -> AnyPublisher<Int, Error>
    func refreshDownloadSize() -> AnyPublisher<Void, Error>
    func deleteDownloads() -> AnyPublisher<Void, Error>
    func pause(_ item: Downloadable) -> AnyPublisher<Void, Error>
    func resume(_ item: Downloadable) -> AnyPublisher<Void, Error>
    func cancel(_ item: Downloadable) -> AnyPublisher<Void, Error>
    func isDownloaded(_ item: Downloadable) -> AnyPublisher<Bool, Error>
}

extension DownloadService {
    func download(_ item: Downloadable, userInfo: [String: Any] = [:]) -> AnyPublisher<Void, Error> {
        download(item, userInfo: userInfo)
    }
}
