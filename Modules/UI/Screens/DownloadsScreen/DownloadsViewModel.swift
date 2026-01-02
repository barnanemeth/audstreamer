//
//  DownloadsViewModel.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 30..
//

import Foundation
import Combine

import Common
import Domain
import UIComponentKit

@Observable
final class DownloadsViewModel: ViewModel {

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

    @ObservationIgnored @Injected private var downloadService: DownloadService
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    private(set) var items = [DownloadingComponent.Data]()
    private(set) var isCompleted = false
    var currentlyShowedDialogDescriptor: DialogDescriptor?

    // MARK: Private properties

    @ObservationIgnored private lazy var singleEvent: AnyPublisher<DownloadEvent, Error> = {
        downloadService.getEvent().shareReplay()
    }()
    @MainActor @ObservationIgnored private let itemsSubject = CurrentValueSubject<[DownloadingComponent.Data], Never>([])
}

// MARK: - View model

extension DownloadsViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.subscribeToAggregatedEvents() }
            taskGroup.addTask { await self.subsribeToItems() }
            taskGroup.addTask { await self.subscribeToCompletedState() }
            taskGroup.addTask { await self.subscribeToFinishEvents() }
        }
    }
}

// MARK: - Actions

extension DownloadsViewModel {
    func handleClose() {
        navigator.dismiss()
    }

    @MainActor
    func pause(_ item: Downloadable) async {
        await performAction(
            with: item,
            type: .pause,
            modifyBlock: { items, index in
                items[index].isPaused = true
            }
        )
    }

    @MainActor
    func resume(_ item: Downloadable) async {
        await performAction(
            with: item,
            type: .resume,
            modifyBlock: { items, index in
                items[index].isPaused = false
            }
        )
    }

    @MainActor
    func cancel(_ item: Downloadable) async {
        await performAction(
            with: item,
            type: .cancel,
            modifyBlock: { items, index in
                items.remove(at: index)
            }
        )
    }
}

// MARK: - Helpers

extension DownloadsViewModel {
    @MainActor
    private func subsribeToItems() async {
        for await downloadingViewData in itemsSubject.asAsyncStream() {
            items = downloadingViewData
        }
    }

    @MainActor
    private func subscribeToAggregatedEvents() async {
        let publisher = downloadService.getAggregatedEvent()
            .map { [unowned self] in self.getItems(from: $0) }
            .replaceError(with: [])
            .removeDuplicates()

        for await items in publisher.asAsyncStream() {
            itemsSubject.send(items)
        }
    }

    @MainActor
    private func subscribeToCompletedState() async {
        let publisher = itemsSubject
            .drop(while: { $0.isEmpty })
            .map { $0.isEmpty }
            .replaceError(with: false)

        for await isCompleted in publisher.asAsyncStream() {
            self.isCompleted = isCompleted
        }
    }

    private func getItems(from aggregatedEvent: DownloadAggregatedEvent) -> [DownloadingComponent.Data] {
        aggregatedEvent.items.map { item in
            DownloadingComponent.Data(item: item, isPaused: false, eventPublisher: getEventPublisher(for: item))
        }
    }

    private func getEventPublisher(for item: Downloadable) -> AnyPublisher<DownloadEvent, Error> {
        singleEvent.filter { $0.item.id == item.id }.shareReplay().eraseToAnyPublisher()
    }

    @MainActor
    private func performAction(with item: Downloadable,
                               type: DownloadActionType,
                               modifyBlock: ((inout [DownloadingComponent.Data], Int) -> Void)? = nil) async {
        var items = itemsSubject.value
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        do {
            switch type {
            case .pause: try await downloadService.pause(item).value
            case .resume: try await downloadService.resume(item).value
            case .cancel: try await downloadService.cancel(item).value
            }

            modifyBlock?(&items, index)
            itemsSubject.send(items)
        } catch {
            showErrorAlert(for: error)
        }
    }

    @MainActor
    private func subscribeToFinishEvents() async {
       let publisher = itemsSubject
            .setFailureType(to: Error.self)
            .map { [unowned self] items -> [AnyPublisher<DownloadEvent, Error>] in
                items.map { self.filterEventPublisherForFinishedEvents($0.eventPublisher) }
            }
            .flatMapLatest { Publishers.MergeMany($0) }
            .delay(for: Constant.finishRemoveDelay, scheduler: DispatchQueue.main)

        do {
            for try await event in publisher.asAsyncStream() {
                var items = itemsSubject.value
                guard let index = items.firstIndex(where: { $0.id == event.item.id }) else { return }
                items.remove(at: index)
                itemsSubject.send(items)
            }
        } catch {
            showErrorAlert(for: error)
        }
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

    private func showErrorAlert(for error: Error) {
        currentlyShowedDialogDescriptor = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
    }
}
