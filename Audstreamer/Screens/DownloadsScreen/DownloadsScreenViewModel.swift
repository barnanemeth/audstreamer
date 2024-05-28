//
//  DownloadsScreenViewModel.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 30..
//

import Foundation
import Combine

final class DownloadsScreenViewModel: ScreenViewModel {

    // MARK: Constants

    private enum Constant {
        static let actionDelay: DispatchQueue.SchedulerTimeType.Stride = 1
        static let finishRemoveDelay: DispatchQueue.SchedulerTimeType.Stride = 1
    }

    private enum DownloadActionType {
        case pause
        case resume
        case cancel
    }

    // MARK: Dependencies

    @Injected private var downloadService: DownloadService

    // MARK: Properties

    @Published var items = [DownloadingCellItem]()
    var isEmpty: AnyPublisher<Bool, Never> {
        $items
            .drop(while: { $0.isEmpty })
            .map { $0.isEmpty }
            .eraseToAnyPublisher()
    }

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private lazy var singleEvent: AnyPublisher<DownloadEvent, Error> = {
        downloadService.getEvent()
            .shareReplay()
            .eraseToAnyPublisher()
    }()

    // MARK: Init

    init() {
        subscribeToAggregatedEvents()
        subscribeToFinishEvents()
    }
}

// MARK: - Actions

extension DownloadsScreenViewModel {
    func itemFinished(_ item: DownloadingCellItem) {
        items.removeAll(where: { $0.id == item.id })
    }

    func pause(_ item: Downloadable, completion: @escaping ((Bool) -> Void)) {
        performAction(
            with: item,
            type: .pause,
            modifyBlock: { [unowned self] in self.items[$0].isPaused = true },
            completion: completion
        )
    }

    func resume(_ item: Downloadable, completion: @escaping ((Bool) -> Void)) {
        performAction(
            with: item,
            type: .resume,
            modifyBlock: { [unowned self] in self.items[$0].isPaused = false },
            completion: completion
        )
    }

    func cancel(_ item: Downloadable, completion: @escaping ((Bool) -> Void)) {
        performAction(
            with: item,
            type: .cancel,
            modifyBlock: { [unowned self] in self.items.remove(at: $0) },
            completion: completion
        )
    }
}

// MARK: - Helpers

extension DownloadsScreenViewModel {
    private func subscribeToAggregatedEvents() {
        downloadService.getAggregatedEvent()
            .map { [unowned self] in self.getItems(from: $0) }
            .replaceError(with: [])
            .removeDuplicates()
            .assign(to: \.items, on: self, ownership: .unowned)
            .store(in: &cancellables)
    }

    private func getItems(from aggregatedEvent: DownloadAggregatedEvent) -> [DownloadingCellItem] {
        aggregatedEvent.items.map { DownloadingCellItem(downloadable: $0, eventPublisher: getEventPublisher(for: $0)) }
    }

    private func getEventPublisher(for item: Downloadable) -> AnyPublisher<DownloadEvent, Error> {
        singleEvent.filter { $0.item.id == item.id }.shareReplay().eraseToAnyPublisher()
    }

    private func performAction(with item: Downloadable,
                               type: DownloadActionType,
                               modifyBlock: ((Int) -> Void)? = nil,
                               completion: @escaping ((Bool) -> Void)) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return completion(false) }

        let action: AnyPublisher<Void, Error>

        switch type {
        case .pause: action = downloadService.pause(item)
        case .resume: action = downloadService.resume(item)
        case .cancel: action = downloadService.cancel(item)
        }

        action
            .handleEvents(receiveCompletion: { subscriptionCompletion in
                switch subscriptionCompletion {
                case .finished: completion(true)
                case .failure: completion(false)
                }
            })
            .delay(for: Constant.actionDelay, scheduler: DispatchQueue.main)
            .map { modifyBlock?(index) }
            .sink()
            .store(in: &cancellables)
    }

    private func subscribeToFinishEvents() {
        $items
            .setFailureType(to: Error.self)
            .map { [unowned self] items -> [AnyPublisher<DownloadEvent, Error>] in
                items.map { self.filterEventPublisherForFinishedEvents($0.eventPublisher) }
            }
            .flatMapLatest { Publishers.MergeMany($0) }
            .delay(for: Constant.finishRemoveDelay, scheduler: DispatchQueue.main)
            .sink { [unowned self] event in
                guard let index = self.items.firstIndex(where: { $0.id == event.item.id }) else { return }
                self.items.remove(at: index)
            }
            .store(in: &cancellables)
    }

    private func filterEventPublisherForFinishedEvents(_ eventPublisher: AnyPublisher<DownloadEvent, Error>)
    -> AnyPublisher<DownloadEvent, Error> {
        eventPublisher
            .filter { event in
                switch event {
                case .finished: return true
                case let .error(_, error as URLError) where error.code == .cancelled: return true
                default: return false
                }
            }
            .eraseToAnyPublisher()
    }
}
