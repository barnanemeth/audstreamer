//
//  PlayerScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation
import Combine

import Reachability
import OrderedCollections

final class PlayerScreenViewModel: ScreenViewModel {

    // MARK: Constants

    private enum Constant {
        static let splitterDateComponents: [Calendar.Component] = [.year, .month]
    }

    // MARK: Dependencies

    @Injected private var database: Database
    @Injected private var audioPlayer: AudioPlayer
    @Injected private var socket: Socket
    @Injected private var playingUpdater: PlayingUpdater
    @Injected private var socketUpdater: SocketUpdater
    @Injected private var databaseUpdater: DatabaseUpdater
    @Injected private var account: Account
    @Injected private var networking: Networking
    @Injected private var cloud: Cloud
    @Injected private var notificationHandler: NotificationHandler
    @Injected private var downloadService: DownloadService
    @Injected private var filterService: FilterService
    @Injected private var shortcutHandler: ShortcutHandler
    @Injected private var watchConnectivityService: WatchConnectivityService

    // MARK: Properties

    @Published var openedEpisodeID: String?
    @Published var searchKeyword: String?
    @Published var isLoading = false
    @Published var isPlayerLoading = false
    @Published var shouldShowButtonInSectionHeaders = true
    var presentErrorAlertAction: Action<Error, Never>?
    var presentCellularWarningAlertAction: Action<([EpisodeData], Int?), Never>?
    var sections: AnyPublisher<[EpisodeSection], Never> {
        Publishers.CombineLatest3(episodes, $openedEpisodeID, isWatchAvailable)
            .map { [unowned self] in self.transformEpisodes(from: $0, openedEpisodeID: $1, isWatchAvailable: $2) }
            .eraseToAnyPublisher()
    }
    var lastPlayedEpisodeID: AnyPublisher<String?, Never> {
        database.getLastPlayedEpisode()
            .map { $0?.id }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    var currentlyPlayingEpisodeID: AnyPublisher<String?, Never> {
        audioPlayer.getCurrentPlayingAudioInfo()
            .map { $0?.id }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    var isLoggedIn: AnyPublisher<Bool, Never> {
        account.isLoggedIn()
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
    var episodeIDFromNotification: AnyPublisher<String?, Never> {
        notificationHandler.getEpisodeID()
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    var episodeIDFromShortcut: AnyPublisher<String?, Never> {
        shortcutHandler.getEpisodeID()
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    var openableEpisodeID: AnyPublisher<String?, Never> {
        Publishers.Zip3(lastPlayedEpisodeID, episodeIDFromNotification, episodeIDFromShortcut)
            .map { $1 ?? $2 ?? $0 }
            .eraseToAnyPublisher()
    }
    var filterAttributes: AnyPublisher<[FilterAttribute], Never> {
        filterService.getAttributes()
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    var isFilterActive: AnyPublisher<Bool, Never> {
        filterAttributes
            .map { $0.contains { $0.isActive } }
            .eraseToAnyPublisher()
    }
    var isEmpty: AnyPublisher<Bool, Never> {
        sections
            .drop(while: { $0.isEmpty })
            .map { $0.isEmpty }
            .eraseToAnyPublisher()
    }
    var isWatchAvailable: AnyPublisher<Bool, Never> {
        watchConnectivityService.isAvailable()
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
    var isWatchConnected: AnyPublisher<Bool, Never> {
        watchConnectivityService.isConnected()
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var episodes: AnyPublisher<[EpisodeData], Never> {
        Publishers.CombineLatest(filterAttributes, $searchKeyword)
            .flatMapLatest { [unowned self] in self.getEpisodes(by: $0, keyword: $1) }
            .eraseToAnyPublisher()
    }
    private lazy var sectionTitleDateFormatte: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constant.splitterDateComponents.dateFormat
        return formatter
    }()

    // MARK: Init

    init() {
        refreshAccount()
        showAndInsertOpenableEpisode()
        startPlayingUpdating()
        startSocketUpdating()
        startDatabaseUpdating()
        subscribeToFiltering()
        subscribeToShortcutEpisode()

        watchConnectivityService.startUpdating()
    }
}

// MARK: - Actions

extension PlayerScreenViewModel {
    func playEpisode(_ episode: EpisodeData) {
        let play = audioPlayer.getCurrentPlayingAudioInfo()
            .map { $0?.id }
            .first()
            .flatMap { [unowned self] id in
                id == episode.id ? self.audioPlayer.play() : self.insertEpisode(episode, playImmediately: true)
            }

        let currentEpisodeSocketData = CurrentEpisodeSocketData(episodeID: episode.id, playImmediately: true)
        let send = socket.sendCurrentEpisode(currentEpisodeSocketData)

        Publishers.Zip(play, send).sink().store(in: &cancellables)
    }

    func downloadDeleteEpisode(_ episode: EpisodeData) {
        if episode.isDownloaded {
            deleteEpisode(episode).sink().store(in: &cancellables)
        } else {
            downloadEpisodesIfPossible([episode])
        }
    }

    func toggleEpisodeFavorite(_ episode: EpisodeData) {
        let isFavorite = !episode.isFavourite

        let databaseUpdate = database.updateEpisode(episode, isFavorite: isFavorite)
        let cloudUpdate = cloud.setFavorite(isFavorite, for: episode.id)

        Publishers.Zip(databaseUpdate, cloudUpdate)
            .sink()
            .store(in: &cancellables)
    }

    func toggleFilterAttribute(_ attribute: FilterAttribute) {
        var attribute = attribute
        attribute.isActive.toggle()
        filterService.setAttribute(attribute).sink().store(in: &cancellables)
    }

    func downloadEpisodes(for section: EpisodeSection) {
        episodes(for: section, isDownloaded: false)
            .replaceError(with: [])
            .sink { [unowned self] in self.downloadEpisodesIfPossible($0) }
            .store(in: &cancellables)
    }

    func deleteEpisodes(for section: EpisodeSection) {
        episodes(for: section, isDownloaded: true)
            .replaceError(with: [])
            .flatMap { [unowned self] in self.deleteEpisodes($0) }
            .sink()
            .store(in: &cancellables)
    }

    func downloadEpisodes(_ episodes: [EpisodeData]) {
        episodes.map { downloadService.download($0) }.zip().sink().store(in: &cancellables)
    }

    func toggleEpisodeIsOnWatch(_ episode: EpisodeData) {
        database.updateEpisode(episode, isOnWatch: !episode.isOnWatch)
            .flatMap { [unowned self] _ -> AnyPublisher<Void, Error> in
                guard !episode.isOnWatch else { return Just.void() }
                return self.watchConnectivityService.cancelFileTransferForEpisode(episode.id)
            }
            .sink()
            .store(in: &cancellables)
    }

    func refresh(_ completion: @escaping () -> Void) {
        FetchUtil.fetchData()
            .sink(receiveCompletion: { _ in completion() }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension PlayerScreenViewModel {
    private func transformEpisodes(from episodes: [EpisodeData],
                                   openedEpisodeID: String?,
                                   isWatchAvailable: Bool) -> [EpisodeSection] {
        let dict = episodes.reduce(into: OrderedDictionary<DateComponents, [EpisodeData]>(), { dictionary, episode in
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

    private func refreshAccount() {
        account.refresh().sink().store(in: &cancellables)
    }

    private func showAndInsertOpenableEpisode() {
        openableEpisodeID
            .setFailureType(to: Error.self)
            .first()
            .handleEvents(receiveOutput: { [unowned self] in self.openedEpisodeID = $0 })
            .unwrap()
            .flatMap { [unowned self] in self.database.getEpisode(id: $0).first() }
            .flatMap { [unowned self] episode -> AnyPublisher<Void, Error> in
                guard let episode = episode else { return Just.void() }

                let currentEpisodeSocketData = CurrentEpisodeSocketData(episodeID: episode.id, playImmediately: true)
                let sendCurrentEpisode = self.socket.sendCurrentEpisode(currentEpisodeSocketData)
                let audioPlayerInsert = self.insertEpisode(episode, playImmediately: false)
                let resetNotificationHandler = self.notificationHandler.resetEpisodeID()

                return Publishers.Zip3(sendCurrentEpisode, audioPlayerInsert, resetNotificationHandler).toVoid()
            }
            .sink()
            .store(in: &cancellables)
    }

    private func insertEpisode(_ episode: EpisodeData, playImmediately: Bool) -> AnyPublisher<Void, Error> {
        audioPlayer.insert(episode, playImmediately: playImmediately)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.isLoading = true },
                          receiveCompletion: { [weak self] _ in self?.isLoading = false },
                          receiveCancel: { [weak self] in self?.isLoading = false })
            .eraseToAnyPublisher()
    }

    private func startPlayingUpdating() {
        playingUpdater.startUpdating().sink().store(in: &cancellables)
    }

    private func startSocketUpdating() {
        socketUpdater.startUpdating().sink().store(in: &cancellables)
    }

    private func startDatabaseUpdating() {
        databaseUpdater.startUpdating().sink().store(in: &cancellables)
    }

    private func deleteEpisode(_ episode: EpisodeData) -> AnyPublisher<Void, Error> {
        downloadService.delete(episode)
            .flatMap { [unowned self] in self.database.updateEpisode(episode, isDownloaded: false) }
            .eraseToAnyPublisher()
    }

    private func isOnlyCellularAvailable() -> Bool {
        @OptionalInjected var reachability: Reachability?
        return reachability?.connection == .cellular
    }

    private func presentCellularWarningAlert(for episodes: [EpisodeData]) {
        let episodeSizes = episodes.map { URLHelper.contentLength(of: $0.url) }.zip()

        episodeSizes
            .map { $0.reduce(.zero, +) }
            .replaceError(with: nil)
            .sink { [unowned self] in self.presentCellularWarningAlertAction?.execute((episodes, $0)) }
            .store(in: &cancellables)
    }

    private func getEpisodes(by filterAttributes: [FilterAttribute],
                             keyword: String?) -> AnyPublisher<[EpisodeData], Never> {
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

    private func subscribeToFiltering() {
        isFilterActive
            .map { !$0 }
            .replaceError(with: false)
            .assign(to: \.shouldShowButtonInSectionHeaders, on: self, ownership: .unowned)
            .store(in: &cancellables)
    }

    private func downloadEpisodesIfPossible(_ episodes: [EpisodeData]) {
        if self.isOnlyCellularAvailable() {
            self.presentCellularWarningAlert(for: episodes)
        } else {
            self.downloadEpisodes(episodes)
        }
    }

    private func subscribeToShortcutEpisode() {
        shortcutHandler.getEpisodeID()
            .unwrap()
            .flatMap { [unowned self] in self.database.getEpisode(id: $0).unwrap().first() }
            .flatMap { [unowned self] in self.audioPlayer.insert($0, playImmediately: true) }
            .sink()
            .store(in: &cancellables)
    }

    private func episodes(for section: EpisodeSection, isDownloaded: Bool) -> AnyPublisher<[EpisodeData], Error> {
        let componentsToDownload = dateComponents(from: section)
        return database.getEpisodes()
            .first()
            .map { episodes -> [EpisodeData] in
                episodes.filter { episode in
                    let components = Calendar.current.dateComponents(
                        Set(Constant.splitterDateComponents),
                        from: episode.publishDate
                    )
                    return components == componentsToDownload && episode.isDownloaded == isDownloaded
                }
            }
            .eraseToAnyPublisher()
    }

    private func deleteEpisodes(_ episodes: [EpisodeData]) -> AnyPublisher<Void, Error> {
        guard !episodes.isEmpty else { return Just.void() }
        return episodes.map { episode in
            downloadService.delete(episode)
                .flatMap { [unowned self] in self.database.updateEpisode(episode, isDownloaded: false) }
        }
        .zip()
        .toVoid()
    }
}
