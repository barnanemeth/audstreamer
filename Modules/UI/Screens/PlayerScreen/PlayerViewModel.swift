//
//  PlayerViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation
import Combine
import UIKit
import SafariServices

import Common
import Domain
import UIComponentKit

internal import Reachability
internal import OrderedCollections

@Observable
final class PlayerViewModel: ViewModel {

    // MARK: Constants

    private enum Constant {
        static let splitterDateComponents: [Calendar.Component] = [.year, .month]
    }

    // MARK: Dependencies

    @ObservationIgnored @Injected private var database: Database
    @ObservationIgnored @Injected private var audioPlayer: AudioPlayer
    @ObservationIgnored @Injected private var socket: Socket
    @ObservationIgnored @Injected private var playingUpdater: PlayingUpdater
    @ObservationIgnored @Injected private var socketUpdater: SocketUpdater
    @ObservationIgnored @Injected private var databaseUpdater: DatabaseUpdater
    @ObservationIgnored @Injected private var cloud: Cloud
    @ObservationIgnored @Injected private var notificationHandler: NotificationHandler
    @ObservationIgnored @Injected private var downloadService: DownloadService
    @ObservationIgnored @Injected private var filterService: FilterService
    @ObservationIgnored @Injected private var shortcutHandler: ShortcutHandler
    @ObservationIgnored @Injected private var watchConnectivityService: WatchConnectivityService
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    private(set) var screenTitle = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? ""
    private(set) var watchConnectionStatus: WatchConnectionStatus = .notAvailable
    private(set) var filterAttributes = [FilterAttribute]()
    private(set) var isFilterActive = false
    private(set) var searchKeyword: String?
    private(set) var sections: [EpisodeSection]?
    private(set) var isLoading = false
    var openedEpisodeID: String?
    var currentlyShowedDialogDescriptor: DialogDescriptor?
    var isPlayerWidgetVisible = false

    // MARK: Private properties

    @ObservationIgnored private lazy var sectionTitleDateFormatte: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constant.splitterDateComponents.dateFormat
        return formatter
    }()

    // MARK: Init

    init() {
        Task {
            watchConnectivityService.startUpdating()
            await withTaskGroup { taskGroup in
                taskGroup.addTask { await self.startSocketUpdating() }
                taskGroup.addTask { await self.startPlayingUpdating() }
                taskGroup.addTask { await self.startDatabaseUpdating() }
                taskGroup.addTask { await self.showAndInsertOpenableEpisode() }
            }
        }
    }
}

// MARK: - View model

extension PlayerViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.startSocketUpdating() }
            taskGroup.addTask { await self.startPlayingUpdating() }
            taskGroup.addTask { await self.startDatabaseUpdating() }
            taskGroup.addTask { await self.subscribeToShortcutEpisode() }
            taskGroup.addTask { await self.subscribeToWatchConnection() }
            taskGroup.addTask { await self.subscribeToFilterAttributes() }
            taskGroup.addTask { await self.subscribeToEpisodes() }
        }
    }
}

// MARK: - Actions

extension PlayerViewModel {
    @MainActor
    func playEpisode(_ episode: Episode) async {
        do {
            try await withThrowingTaskGroup { taskGroup in
                taskGroup.addTask {
                    let currentPlayingAudioInfo = try await self.audioPlayer.getCurrentPlayingAudioInfo().value
                    if currentPlayingAudioInfo?.id == episode.id {
                        try await self.audioPlayer.play().value
                    } else {
                        try await self.insertEpisode(episode, playImmediately: true)
                    }
                }

                taskGroup.addTask {
                    let currentEpisodeSocketData = CurrentEpisodeSocketData(episodeID: episode.id, playImmediately: true)
                    try await self.socket.sendCurrentEpisode(currentEpisodeSocketData).value
                }

                try await taskGroup.waitForAll()
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

    func downloadDeleteEpisode(_ episode: Episode) async {
        if episode.isDownloaded {
            try? await deleteEpisode(episode)
        } else {
            await downloadEpisodesIfPossible([episode])
        }
    }

    @MainActor
    func toggleEpisodeFavorite(_ episode: Episode) async {
        do {
            let isFavorite = !episode.isFavourite
            try await withThrowingTaskGroup { taskGroup in
                taskGroup.addTask {
                    try await self.database.updateEpisode(episode, isFavorite: isFavorite).value
                }

                taskGroup.addTask {
                    try await self.cloud.setFavorite(isFavorite, for: episode.id).value
                }

                try await taskGroup.waitForAll()
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

    func toggleFilterAttribute(_ attribute: FilterAttribute) {
        Task {
            var attribute = attribute
            attribute.isActive.toggle()
            try? await filterService.setAttribute(attribute).value
        }
    }

    @MainActor
    func downnloadOrDeletedEpisodes(for section: EpisodeSection) async {
        do {
            if section.isDownloaded {
                try await deleteEpisodes(for: section)
            } else {
                try await downloadEpisodes(for: section)
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

    @MainActor
    func downloadEpisodes(_ episodes: [Episode]) async {
        await withTaskGroup { taskGroup in
            episodes.forEach { episode in
                taskGroup.addTask { try? await self.downloadService.download(episode).value }
            }
            await taskGroup.waitForAll()
        }
    }

    @MainActor
    func toggleEpisodeIsOnWatch(_ episode: Episode) async {
        do {
            let isOnWatch = !episode.isOnWatch
            try await database.updateEpisode(episode, isOnWatch: isOnWatch).value
            if isOnWatch {
                try await watchConnectivityService.transferEpisode(episode.id).value
            } else {
                try await watchConnectivityService.cancelFileTransferForEpisode(episode.id).value
            }
        } catch {
            showErrorAlert(for: error)
        }
    }

    @MainActor
    func refresh() async {
        try? await FetchUtil.fetchData().value
    }

    func setSearchKeyword(_ keyword: String) {
        if keyword.isEmpty {
            searchKeyword = nil
        } else {
            searchKeyword = keyword
        }
    }

    @MainActor
    func navigateToSettings() {
        isPlayerWidgetVisible = false
        navigator.navigate(to: .settings, method: .push)
    }

    @MainActor
    func navigateToDownloads() {
        isPlayerWidgetVisible = false
        navigator.navigate(to: .downloads, method: .push)
    }
}

// MARK: - Helpers

extension PlayerViewModel {
    @MainActor
    private func subscribeToWatchConnection() async {
        let availabilityPublisher = watchConnectivityService.isAvailable().prepend(false)
        let connectedPublisher = watchConnectivityService.isConnected().prepend(false)
        let publisher = Publishers.CombineLatest(availabilityPublisher, connectedPublisher)
            .map { isAvailable, isConnected -> WatchConnectionStatus in
                return switch (isAvailable, isConnected) {
                case (false, _): .notAvailable
                case (true, false): .available
                case (true, true): .connected
                }
            }
            .replaceError(with: .notAvailable)

        for await connectionStatus in publisher.asAsyncStream() {
            watchConnectionStatus = connectionStatus
        }
    }

    @MainActor
    private func subscribeToFilterAttributes() async {
        let publisher = filterService.getAttributes().replaceError(with: [])
        for await attributes in publisher.asAsyncStream() {
            filterAttributes = attributes
            isFilterActive = attributes.contains(where: { $0.isActive })
        }
    }

    @MainActor
    private func subscribeToEpisodes() async {
        let filterAttributes = ObservationTrackingPublisher(self.filterAttributes)
        let searchKeyword = ObservationTrackingPublisher(self.searchKeyword)
        let episodesPublisher = Publishers.CombineLatest(filterAttributes, searchKeyword)
            .flatMapLatest { [unowned self] in getEpisodes(by: $0, keyword: $1) }
        let openedEpisodeIDPublisher = ObservationTrackingPublisher(self.openedEpisodeID)
        let isWatchAvailable = watchConnectivityService.isAvailable().replaceError(with: false)
        let publisher = Publishers.CombineLatest3(episodesPublisher, openedEpisodeIDPublisher, isWatchAvailable)

        for await (episodes, openedEpisodeID, isWatchAvailable) in publisher.asAsyncStream() {
            sections = transformEpisodes(from: episodes, openedEpisodeID: openedEpisodeID, isWatchAvailable: isWatchAvailable)
        }
    }

    private func transformEpisodes(from episodes: [Episode],
                                   openedEpisodeID: String?,
                                   isWatchAvailable: Bool) -> [EpisodeSection] {
        let dict = episodes.reduce(into: OrderedDictionary<DateComponents, [Episode]>(), { dictionary, episode in
            let components = Calendar.current.dateComponents(
                Set(Constant.splitterDateComponents),
                from: episode.publishDate
            )
            if dictionary[components] == nil {
                dictionary[components] = [episode]
            } else {
                dictionary[components]?.append(episode)
            }
        })

        let sections = dict.reduce(into: [EpisodeSection](), { sections, item in
            let dateComponents = item.key
            let episodes = item.value

            let sectionsToAdd = episodes.enumerated().map { offset, episode -> EpisodeSection in
                var title: String?
                var isDownloaded = false
                if offset == .zero, let date = Calendar.current.date(from: dateComponents) {
                    title = sectionTitleDateFormatte.string(from: date)
                    isDownloaded = episodes.allSatisfy { $0.isDownloaded }
                }
                return EpisodeSection(
                    episode: episode,
                    isOpened: episode.id == openedEpisodeID,
                    title: title,
                    isDownloaded: isDownloaded,
                    isWatchAvailable: isWatchAvailable
                )
            }

            sections.append(contentsOf: sectionsToAdd)
        })

        return sections
    }

    private func showAndInsertOpenableEpisode() async {
        do {
            let lastPlayedEpisodeID = try await database.getLastPlayedEpisode().value?.id
            let episodeIDFromNotification = try await  notificationHandler.getEpisodeID().value
            let episodeIDFromShortcut = try await  shortcutHandler.getEpisodeID().value

            openedEpisodeID = lastPlayedEpisodeID

            guard let episodeID = episodeIDFromNotification ?? episodeIDFromShortcut ?? lastPlayedEpisodeID,
                  let episode = try await database.getEpisode(id: episodeID).value  else { return }

            try await withThrowingTaskGroup { taskGroup in
                taskGroup.addTask {
                    let currentEpisodeSocketData = CurrentEpisodeSocketData(episodeID: episode.id, playImmediately: true)
                    try await self.socket.sendCurrentEpisode(currentEpisodeSocketData).value
                }
                taskGroup.addTask {
                    try await self.insertEpisode(episode, playImmediately: false)
                }
                taskGroup.addTask {
                    try await self.notificationHandler.resetEpisodeID().value
                }

                try await taskGroup.waitForAll()
            }
        } catch {
            return
        }
    }

    @MainActor
    private func insertEpisode(_ episode: Episode, playImmediately: Bool) async throws {
        defer { isLoading = false }
        isLoading = true
        try await audioPlayer.insert(episode, playImmediately: playImmediately).value
    }

    private func startPlayingUpdating() async {
        try? await playingUpdater.startUpdating().value
    }

    private func startSocketUpdating() async {
        try? await socketUpdater.startUpdating().value
    }

    private func startDatabaseUpdating() async {
        try? await databaseUpdater.startUpdating().value
    }

    private func deleteEpisode(_ episode: Episode) async throws {
        try await downloadService.delete(episode).value
        try await database.updateEpisode(episode, isDownloaded: false).value
    }

    private func isOnlyCellularAvailable() -> Bool {
        @OptionalInjected var reachability: Reachability?
        return reachability?.connection == .cellular
    }

    @MainActor
    private func presentCellularWarningAlert(for episodes: [Episode]) async {
        do {
            let size: Int = try await withThrowingTaskGroup { taskGroup in
                episodes.forEach { episode in
                    taskGroup.addTask { try await URLHelper.contentLength(of: episode.mediaURL) }
                }

                return try await taskGroup.reduce(.zero, +)
            }
            presentCellularWarningAlert(for: episodes, contentLength: size)
        } catch {
            showErrorAlert(for: error)
        }
    }

    private func getEpisodes(by filterAttributes: [FilterAttribute],
                             keyword: String?) -> AnyPublisher<[Episode], Never> {
        let filterFavorites = filterAttributes.contains { $0.type == .favorites && $0.isActive }
        let filterDownloads = filterAttributes.contains { $0.type == .downloads && $0.isActive }
        let filterWatch = filterAttributes.contains { $0.type == .watch && $0.isActive }

        return database.getEpisodes(
            filterFavorites: filterFavorites,
            filterDownloads: filterDownloads,
            filterWatch: filterWatch,
            keyword: keyword
        )
        .replaceError(with: [])
        .eraseToAnyPublisher()
    }

    private func dateComponents(from section: EpisodeSection) -> DateComponents {
        Calendar.current.dateComponents(Set(Constant.splitterDateComponents), from: section.episode.publishDate)
    }

    @MainActor
    private func downloadEpisodesIfPossible(_ episodes: [Episode]) async {
        if isOnlyCellularAvailable() {
            await presentCellularWarningAlert(for: episodes)
        } else {
            await downloadEpisodes(episodes)
        }
    }

    private func subscribeToShortcutEpisode() async {
        let publisher = shortcutHandler.getEpisodeID().replaceError(with: nil).unwrap()
        for await episodeID in publisher.asAsyncStream() {
            guard let episode = try? await database.getEpisode(id: episodeID).value else { continue }
            try? await audioPlayer.insert(episode, playImmediately: true).value
        }
    }

    private func episodes(for section: EpisodeSection, isDownloaded: Bool) async throws -> [Episode] {
        let componentsToDownload = dateComponents(from: section)
        let episodes = try await database.getEpisodes().value
        return episodes.filter { episode in
            let components = Calendar.current.dateComponents(
                Set(Constant.splitterDateComponents),
                from: episode.publishDate
            )
            return components == componentsToDownload && episode.isDownloaded == isDownloaded
        }
    }

    private func deleteEpisodes(_ episodes: [Episode]) async throws {
        try await withThrowingTaskGroup { taskGroup in
            episodes.forEach { episode in
                taskGroup.addTask {
                    try await self.downloadService.delete(episode).value
                    try await self.database.updateEpisode(episode, isDownloaded: false).value
                }
            }
            try await taskGroup.waitForAll()
        }
    }

    private func presentCellularWarningAlert(for episodes: [Episode], contentLength: Int?) {
        currentlyShowedDialogDescriptor = DialogDescriptor(
            title: L10n.download,
            message: getCellularWarningMessage(episodesCount: episodes.count, contentLength: contentLength),
            type: .alert,
            actions: [
                DialogAction(
                    title: L10n.laterOnWifi,
                    type: .normal
                ),
                DialogAction(
                    title: L10n.download,
                    type: .normal,
                    action: { [unowned self] in Task { @MainActor in await downloadEpisodes(episodes) } }
                )
            ]
        )
    }

    private func getCellularWarningMessage(episodesCount: Int, contentLength: Int?) -> String {
        var message = ""
        if let contentLength = contentLength {
            message += L10n.downloadSize(
                episodesCount,
                NumberFormatterHelper.getFormattedContentSize(from: contentLength)
            )
            message += " "
        }
        message += L10n.downloadCellularWarningMessage
        return message
    }

    private func showErrorAlert(for error: Error) {
        currentlyShowedDialogDescriptor = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
    }

    private func downloadEpisodes(for section: EpisodeSection) async throws {
        let episodes = try await episodes(for: section, isDownloaded: false)
        await downloadEpisodesIfPossible(episodes)
    }

    private func deleteEpisodes(for section: EpisodeSection) async throws {
        let episodes = try await episodes(for: section, isDownloaded: true)
        try await deleteEpisodes(episodes)
    }
}

