//
//  EpisodeListViewModel.swift
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
final class EpisodeListViewModel {

    // MARK: Constants

    private enum Constant {
        static let splitterDateComponents: [Calendar.Component] = [.year, .month]
    }

    // MARK: Dependencies

    @ObservationIgnored @Injected private var episodeService: EpisodeService
    @ObservationIgnored @Injected private var audioPlayer: AudioPlayer
    @ObservationIgnored @Injected private var socket: Socket
    @ObservationIgnored @Injected private var cloud: Cloud
    @ObservationIgnored @Injected private var notificationHandler: NotificationHandler
    @ObservationIgnored @Injected private var filterHelper: FilterHelper
    @ObservationIgnored @Injected private var shortcutHandler: ShortcutHandler
    @ObservationIgnored @Injected private var watchConnectivityService: WatchConnectivityService
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    private(set) var screenTitle = About.appName
    private(set) var filterAttributes = [FilterAttribute]()
    private(set) var isFilterActive = false
    private(set) var searchKeyword: String?
    private(set) var sections: [EpisodeSection]?
    private(set) var podcast: Podcast?
    var openedEpisodeID: String?
    var currentlyShowedDialogDescriptor: DialogDescriptor?

    // MARK: Private properties

    @ObservationIgnored private lazy var sectionTitleDateFormatte: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constant.splitterDateComponents.dateFormat
        return formatter
    }()
    @ObservationIgnored private var currentlyPlayingID: AnyPublisher<String?, Error> {
        Publishers.CombineLatest(audioPlayer.getCurrentPlayingAudioInfo().map(\.?.id), audioPlayer.isPlaying())
            .map { $1 ? $0 : nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - View model

extension EpisodeListViewModel: ViewModel {
    func subscribe() async {
        await withTaskGroup { taskGroup in
            taskGroup.addTask { await self.openLastPlayedEpisodeIfNeeded() }
            taskGroup.addTask { await self.subscribeToShortcutEpisode() }
            taskGroup.addTask { await self.subscribeToFilterAttributes() }
            taskGroup.addTask { await self.subscribeToEpisodes() }
        }
    }
}

// MARK: - Actions

extension EpisodeListViewModel {
    func setPodcast(_ podcast: Podcast?) {
        self.podcast = podcast
    }

    @MainActor
    func togglePlaying(_ episode: Episode) async {
        do {
            let currentlyPlayingID = try await currentlyPlayingID.value
            if currentlyPlayingID == episode.id {
                try await pausePlaying()
            } else {
                try await playEpisode(episode)
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
                    try await self.episodeService.setFavorite(episode, isFavorite: isFavorite).value
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
            try? await filterHelper.setAttribute(attribute).value
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
                taskGroup.addTask { try? await self.episodeService.download(episode).value }
            }
            await taskGroup.waitForAll()
        }
    }

    @MainActor
    func toggleEpisodeIsOnWatch(_ episode: Episode) async {
        do {
            let isOnWatch = !episode.isOnWatch
            if isOnWatch {
                try await episodeService.sendToWatch(episode).value
            } else {
                try await episodeService.removeFromWatch(episode).value
            }
        } catch {
            showErrorAlert(for: error)
        }
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
        navigator.navigate(to: .settings, method: .push)
    }

    @MainActor
    func navigateToDownloads() {
        navigator.navigate(to: .downloads, method: .push)
    }
}

// MARK: - Helpers

extension EpisodeListViewModel {
    @MainActor
    private func subscribeToFilterAttributes() async {
        let publisher = filterHelper.getAttributes().replaceError(with: [])
        for await attributes in publisher.asAsyncStream() {
            filterAttributes = attributes
            isFilterActive = attributes.contains(where: { $0.isActive })
        }
    }

    @MainActor
    private func subscribeToEpisodes() async {
        let filterAttributes = ObservationTrackingPublisher(self.filterAttributes)
        let searchKeyword = ObservationTrackingPublisher(self.searchKeyword)
        let podcast = ObservationTrackingPublisher(self.podcast)
        let episodesPublisher = Publishers.CombineLatest3(filterAttributes, searchKeyword, podcast)
            .flatMapLatest { [unowned self] in getEpisodes(by: $0, keyword: $1, podcast: $2) }

        let openedEpisodeIDPublisher = ObservationTrackingPublisher(self.openedEpisodeID)
        let isWatchAvailable = watchConnectivityService.isAvailable().replaceError(with: false)
        let currentlyPlayingID = currentlyPlayingID.replaceError(with: nil)

        let publisher = Publishers.CombineLatest4(episodesPublisher, openedEpisodeIDPublisher, isWatchAvailable, currentlyPlayingID)

        for await (episodes, openedEpisodeID, isWatchAvailable, currentlyPlayingID) in publisher.asAsyncStream() {
            sections = transformEpisodes(
                from: episodes,
                openedEpisodeID: openedEpisodeID,
                currentlyPlayingID: currentlyPlayingID,
                isWatchAvailable: isWatchAvailable
            )
        }
    }

    private func transformEpisodes(from episodes: [Episode],
                                   openedEpisodeID: String?,
                                   currentlyPlayingID: String?,
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
                    isPlaying: currentlyPlayingID == episode.id,
                    isDownloaded: isDownloaded,
                    isWatchAvailable: isWatchAvailable
                )
            }

            sections.append(contentsOf: sectionsToAdd)
        })

        return sections
    }

    @MainActor
    private func openLastPlayedEpisodeIfNeeded() async {
        openedEpisodeID = try? await episodeService.lastPlayedEpisode().value?.id
    }

    @MainActor
    private func insertEpisode(_ episode: Episode, playImmediately: Bool) async throws {
        try await audioPlayer.insert(episode, playImmediately: playImmediately).value
    }

    private func deleteEpisode(_ episode: Episode) async throws {
        try await episodeService.deleteDownload(for: episode).value
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

    private func getEpisodes(by filterAttributes: [FilterAttribute], keyword: String?, podcast: Podcast?) -> AnyPublisher<[Episode], Never> {
        let queryAttributes = EpisodeQueryAttributes(
            keyword: keyword,
            filterFavorites: filterAttributes.contains { $0.type == .favorites && $0.isActive },
            filterDownloads: filterAttributes.contains { $0.type == .downloads && $0.isActive },
            filterWatch: filterAttributes.contains { $0.type == .watch && $0.isActive },
            podcastID: podcast?.id
        )

        return episodeService.episodes(matching: queryAttributes)
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
            guard let episode = try? await episodeService.episode(id: episodeID).value else { continue }
            try? await audioPlayer.insert(episode, playImmediately: true).value
        }
    }

    private func episodes(for section: EpisodeSection, isDownloaded: Bool) async throws -> [Episode] {
        let componentsToDownload = dateComponents(from: section)
        let episodes = try await episodeService.episodes(matching: EpisodeQueryAttributes(filterDownloads: isDownloaded, podcastID: podcast?.id)).value
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
                    try await self.episodeService.deleteDownload(for: episode).value
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

    private func playEpisode(_ episode: Episode) async throws {
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
    }

    private func pausePlaying() async throws {
        try await withThrowingTaskGroup { taskGroup in
            taskGroup.addTask { try await self.audioPlayer.pause().value }
            taskGroup.addTask { try await self.socket.sendPlaybackCommand(.pause).value }

            try await taskGroup.waitForAll()
        }
    }
}

