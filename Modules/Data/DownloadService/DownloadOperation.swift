//
//  DownloadOperation.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 04..
//

import Foundation
import Combine

import Common
import Domain

final class DownloadOperation: AsyncOperation {

    // MARK: Properties

    let item: Downloadable
    var id: String { item.id }
    var eventPublisher: AnyPublisher<DownloadEvent, Error> {
        eventSubject.eraseToAnyPublisher()
    }

    // MARK: Private properties

    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    private let fileManager = FileManager.default
    private let eventSubject = PassthroughSubject<DownloadEvent, Error>()
    private var downloadTask: URLSessionDownloadTask?

    // MARK: Init

    init(item: Downloadable) {
        self.item = item
    }

    // MARK: Public methods

    override func main() {
        createDirectoryIfNeeded()

        let request = URLRequest(url: item.remoteURL)
        downloadTask = session.downloadTask(with: request)

        startIfPossible()
    }

    override func cancel() {
        downloadTask?.cancel()
    }

    override func suspend() {
        super.suspend()
        downloadTask?.suspend()
    }

    override func resume() {
        super.resume()
        downloadTask?.resume()
    }
}

// MARK: - Helpers

extension DownloadOperation {
    private func startIfPossible() {
        guard isExecuting else { return }
        downloadTask?.resume()
    }

    private func createDirectoryIfNeeded() {
        guard let directoryURL = URLHelper.destinationDirectory else { return }

        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)
        if !exists || !isDirectory.boolValue {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}

// MARK: - URLSessionDataDelegate

extension DownloadOperation: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let progress = Progress(totalUnitCount: totalBytesExpectedToWrite)
        progress.completedUnitCount = totalBytesWritten
        eventSubject.send(.inProgress(item: item, progress: progress))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let destinationURL = item.possibleLocalURL else { return }
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            finish(with: .finished(item: item))
        } catch {
            finish(with: .error(item: item, error: error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        finish(with: .error(item: item, error: error))
    }
}

// MARK: - Helpers

extension DownloadOperation {
    private func finish(with event: DownloadEvent) {
        eventSubject.send(event)
        eventSubject.send(completion: .finished)
        session.finishTasksAndInvalidate()
        finish()
    }
}
