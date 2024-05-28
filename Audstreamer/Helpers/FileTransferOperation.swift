//
//  FileTransferOperation.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 01/11/2023.
//

import Foundation
import Combine
import WatchConnectivity

final class FileTransferOperation: AsyncOperation {

    // MARK: Properties

    var id: String {
        fileTransfer.id ?? UUID().uuidString
    }
    var progressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    // MARK: Private properties

    private let fileTransfer: WCSessionFileTransfer
    private let progressSubject = CurrentValueSubject<Double, Never>(.zero)
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init(fileTransfer: WCSessionFileTransfer) {
        self.fileTransfer = fileTransfer

        progressSubject.send(fileTransfer.progress.fractionCompleted)
    }

    // MARK: Public methods

    override func main() {
        let fractionCompletedPublisher = fileTransfer.progress.publisher(for: \.fractionCompleted)
        let isFinished = fileTransfer.progress.publisher(for: \.isFinished)

        Publishers.CombineLatest(fractionCompletedPublisher, isFinished)
            .sink { [weak self] fractionCompleted, isFinished in
                if isFinished {
                    self?.progressSubject.send(1)
                    self?.finish()
                } else {
                    self?.progressSubject.send(fractionCompleted)
                }
            }
            .store(in: &cancellables)
    }

    override func cancel() {
        finish()
    }

    // MARK: Helpers

    override func finish() {
        fileTransfer.cancel()
        progressSubject.send(completion: .finished)
        super.finish()
    }
}
