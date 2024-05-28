//
//  DownloadService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 04..
//

import Foundation
import Combine

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

enum DownloadServiceError: Error {
    case badDirectoryURL
    case connectionUnavailable
}

enum DownloadEvent {

    // MARK: Cases

    case queued(item: Downloadable)
    case inProgress(item: Downloadable, progress: Progress)
    case finished(item: Downloadable)
    case error(item: Downloadable, error: Error)
    case deleted(item: Downloadable)

    // MARK: Properties

    var item: Downloadable {
        switch self {
        case let .queued(item): return item
        case let .inProgress(item, _): return item
        case let .finished(item): return item
        case let .error(item, _): return item
        case let .deleted(item): return item
        }
    }
}

struct DownloadAggregatedEvent: Hashable, Equatable {

    // MARK: Properties

    let items: [Downloadable]
    let progress: Progress
    let userInfo: [String: Any]?

    // MARK: Hashable & Equatable

    func hash(into hasher: inout Hasher) {
        hasher.combine(items.map(\.id))
        hasher.combine(progress.fractionCompleted)
    }

    static func == (_ lhs: DownloadAggregatedEvent, _ rhs: DownloadAggregatedEvent) -> Bool {
        lhs.items.map(\.id) == rhs.items.map(\.id) && lhs.progress.fractionCompleted == rhs.progress.fractionCompleted
    }
}

protocol Downloadable {
    var id: String { get }
    var title: String { get }
    var remoteURL: URL { get }
    var userInfo: [String: Any]? { get }
}
