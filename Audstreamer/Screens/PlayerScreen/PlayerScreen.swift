//
//  PlayerScreen.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

// swiftlint:disable file_length

import UIKit
import Combine
import SafariServices

import SFSafeSymbols

final class PlayerScreen: UIViewController, Screen {

    // MARK: Typealiases

    private typealias DataSource = UITableViewDiffableDataSource<EpisodeSection, EpisodeSection.EpisodeItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<EpisodeSection, EpisodeSection.EpisodeItem>

    // MARK: Constants

    private enum Constant {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 8
        static let sectionHeaderHeight: CGFloat = 8
        static let sectionFooterHeight: CGFloat = 8
        static let bottomInset: CGFloat = 170
    }

    // MARK: Screen

    @Injected var viewModel: PlayerScreenViewModel

    // MARK: UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private lazy var refreshControl: UIRefreshControl = {
        let action = UIAction { [weak self] _ in
            self?.viewModel.refresh { self?.refreshControl.endRefreshing() }
        }
        return UIRefreshControl(frame: .zero, primaryAction: action)
    }()
    private let emptyStateView = EmptyStateView(
        image: Asset.symbol(.exclamationmarkCircle, scale: .large),
        title: L10n.noResults
    )
    private let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: nil, action: nil)
    #if targetEnvironment(macCatalyst)
    private lazy var filterButtonCustomButton: UIButton = {
        let button = UIButton()
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    #endif
    private lazy var filterButton: UIBarButtonItem = {
        #if targetEnvironment(macCatalyst)
        let barButton = UIBarButtonItem(image: Asset.symbol(.line3HorizontalDecreaseCircle, scale: .large))
        barButton.customView = filterButtonCustomButton
        return barButton
        #else
        return UIBarButtonItem(image: Asset.symbol(.line3HorizontalDecreaseCircle, scale: .large))
        #endif
    }()
    private let settingsButton = UIBarButtonItem(image: UIImage(systemSymbol: .gear))
    private let searchController = UISearchController(searchResultsController: nil)
    private let playerWidget = PlayerWidget()
    private let downloadWidget = DownloadWidget()
    private let fileTransferWidget = FileTransferWidget()
    private let watchButton = UIBarButtonItem(image: UIImage(systemSymbol: .applewatch))

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var sections = [EpisodeSection]()
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private lazy var dataSource: DataSource = {
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { [unowned self] in self.dequeueCell(from: $0, with: $1, for: $2) }
        )
        dataSource.defaultRowAnimation = .fade
        return dataSource
    }()
    private var firstUpdate: AnyPublisher<([EpisodeSection], String?), Never> {
        let sections = viewModel.sections.first()
        let openableEpisodeID = viewModel.openableEpisodeID.first()
        return Publishers.Zip(sections, openableEpisodeID).eraseToAnyPublisher()
    }
}

// MARK: - Lifecycle

extension PlayerScreen {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBindings()
    }
}

// MARK: - Setups

extension PlayerScreen {
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground

        setupTitle()
        setupLeftNavigationItem()
        setupRightNavigationItems()
        setupTableView()
        setupEmptyStateView()
        setupSearchController()
        setupPlayerWidget()
        setupDownloadWidget()
        setupFileTransferWidget()
    }

    private func setupTitle() {
        title = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }

    private func setupWatchButton() {
        watchButton.isEnabled = false
    }

    private func setupLeftNavigationItem() {
        navigationItem.leftBarButtonItems = getLeftBarButtonItems(isWatchButtonVisible: false)
    }

    private func setupRightNavigationItems() {
        navigationItem.rightBarButtonItems = [settingsButton, filterButton]
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.delaysContentTouches = false
        tableView.separatorStyle = .singleLine
        tableView.estimatedSectionHeaderHeight = PlayerSectionHeaderView.Constant.height
        tableView.separatorInset = UIEdgeInsets(top: .zero, left: 32, bottom: .zero, right: 32)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        let bottomInset = Constant.bottomInset + view.safeAreaInsets.bottom + Constant.verticalPadding
        tableView.contentInset = UIEdgeInsets(
            top: Constant.verticalPadding,
            left: .zero,
            bottom: bottomInset,
            right: .zero
        )

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = EpisodeInfoCell.Constant.minimumHeight
        tableView.sectionHeaderHeight = Constant.sectionHeaderHeight
        tableView.sectionFooterHeight = Constant.sectionFooterHeight
        #if !targetEnvironment(macCatalyst)
        tableView.refreshControl = refreshControl
        #endif

        tableView.register(EpisodeInfoCell.self, forCellReuseIdentifier: EpisodeInfoCell.reusdeIdentifier)
        tableView.register(EpisodeDetailCell.self, forCellReuseIdentifier: EpisodeDetailCell.reusdeIdentifier)
        tableView.register(
            PlayerSectionHeaderView.self,
            forHeaderFooterViewReuseIdentifier: PlayerSectionHeaderView.reusdeIdentifier
        )

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyStateView() {
        emptyStateView.isHidden = true
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor,
                constant: -PlayerSectionHeaderView.Constant.height
            )
        ])
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self

        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupPlayerWidget() {
        view.addSubview(playerWidget)
        playerWidget.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playerWidget.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -Constant.verticalPadding
            ),
            playerWidget.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constant.horizontalPadding),
            playerWidget.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constant.horizontalPadding)
        ])
    }

    private func setupDownloadWidget() {
        downloadWidget.setup(with: view)
    }

    private func setupFileTransferWidget() {
        fileTransferWidget.setup(with: view)
    }

    private func setupBindings() {
        setupViewModelBindings()

        searchButton.tapPublisher
            .sink { [unowned self] in
                self.searchController.isActive.toggle()
                if self.searchController.isActive {
                    self.searchController.searchBar.becomeFirstResponder()
                }
            }
            .store(in: &cancellables)

        playerWidget.titleTapAction = CocoaAction { [unowned self] in
            self.viewModel.currentlyPlayingEpisodeID
                .first()
                .sink { episodeID in
                    self.triggerFeedback()
                    self.scrollToCell(with: episodeID, isAnimated: true)
                }
                .store(in: &cancellables)
        }

        settingsButton.tapPublisher
            .sink { [unowned self] in viewModel.navigateToSettings() }
            .store(in: &cancellables)

        downloadWidget.tapAction = CocoaAction { [unowned self] in viewModel.navigateToDownloads() }
        playerWidget.remotePlayButtonTap = CocoaAction { [unowned self] in viewModel.showDevices(sourceView: playerWidget.remotePlaySourceView) }
    }

    private func setupViewModelBindings() {
        firstUpdate
            .handleEvents(receiveOutput: { [unowned self] in self.sections = $0.0 })
            .sink { [unowned self] in self.update(with: $0, openableEpisodeID: $1) }
            .store(in: &cancellables)

        viewModel.sections
            .drop(untilOutputFrom: firstUpdate)
            .handleEvents(receiveOutput: { [unowned self] in self.sections = $0 })
            .sink { [unowned self] in self.update(with: $0, openableEpisodeID: nil) }
            .store(in: &cancellables)

        viewModel.isEmpty
            .sink { [unowned self] in self.updateEmptyState(isEmpty: $0) }
            .store(in: &cancellables)

        viewModel.$isLoading
            .assign(to: \.isLoading, on: playerWidget.viewModel, ownership: .unowned)
            .store(in: &cancellables)

        viewModel.filterAttributes
            .sink { [unowned self] in self.updateFilterMenu(with: $0) }
            .store(in: &cancellables)

        viewModel.isFilterActive
            .sink { [unowned self] in self.updateFilterButton(isActive: $0) }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.isWatchAvailable, viewModel.isWatchConnected)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] isWatchAvailable, isWatchConnected in
                self.watchButton.tintColor = isWatchConnected ? Asset.Colors.primary.color : Asset.Colors.disabled.color
                self.updateLeftBarButtonItems(isWatchButtonVisible: isWatchAvailable)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension PlayerScreen {
    private func update(with sections: [EpisodeSection], openableEpisodeID: String?) {
        var snapshot = Snapshot()
        snapshot.appendSections(sections)
        sections.forEach { snapshot.appendItems($0.items, toSection: $0) }
        dataSource.apply(snapshot, animatingDifferences: true) { [unowned self] in
            self.scrollToCell(with: openableEpisodeID, isAnimated: false)
        }
    }

    private func dequeueCell(from tableView: UITableView,
                             with indexPath: IndexPath,
                             for item: EpisodeSection.EpisodeItem) -> UITableViewCell? {
        switch item {
        case let .info(episode, _, _, _):
            return dequeueEpisodeInfoCell(from: tableView, with: indexPath, for: episode)
        case let .detail(episode, _, _, _, _, isWatchAvailable):
            return dequeueEpisodeDetailCell(
                from: tableView,
                with: indexPath,
                for: episode,
                isWatchAvailable: isWatchAvailable
            )
        }
    }

    private func dequeueEpisodeInfoCell(from tableView: UITableView,
                                        with indexPath: IndexPath,
                                        for episode: Episode) -> EpisodeInfoCell? {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: EpisodeInfoCell.reusdeIdentifier,
            for: indexPath
        ) as? EpisodeInfoCell else { return nil }
        cell.setup(with: episode)
        return cell
    }

    private func dequeueEpisodeDetailCell(from tableView: UITableView,
                                          with indexPath: IndexPath,
                                          for episode: Episode,
                                          isWatchAvailable: Bool) -> EpisodeDetailCell? {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: EpisodeDetailCell.reusdeIdentifier,
            for: indexPath
        ) as? EpisodeDetailCell else { return nil }
        cell.setup(with: episode, isWatchAvailable: isWatchAvailable)
        cell.playAction = actionTrigger { [unowned self] in viewModel.playEpisode(episode) }
        cell.linkAction = actionTrigger { [unowned self] in viewModel.navigateToWebView(for: episode) }
        cell.downloadDeleteAction = actionTrigger { [unowned self] in viewModel.downloadDeleteEpisode(episode) }
        cell.favoriteAction = actionTrigger { [unowned self] in viewModel.toggleEpisodeFavorite(episode) }
        cell.watchAction = actionTrigger { [unowned self] in viewModel.toggleEpisodeIsOnWatch(episode) }
        return cell
    }

    private func scrollToCell(with episodeID: String?, isAnimated: Bool) {
        guard let episodeID = episodeID,
              let sectionIndex = self.sections.firstIndex(where: { $0.episodeID == episodeID }) else { return }
        tableView.scrollToRow(at: IndexPath(row: .zero, section: sectionIndex), at: .top, animated: isAnimated)
    }

    private func triggerFeedback() {
        self.feedbackGenerator.prepare()
        self.feedbackGenerator.impactOccurred()
    }

    private func actionTrigger(_ block: @escaping (() -> Void)) -> CocoaAction {
        CocoaAction { [unowned self] in
            self.triggerFeedback()
            block()
        }
    }

    private func updateFilterMenu(with attributes: [FilterAttribute]) {
        let actions = attributes.map { attribute in
            let state: UIAction.State = attribute.isActive ? .on : .off
            let handler: UIActionHandler = { [unowned self] _ in self.viewModel.toggleFilterAttribute(attribute) }
            return UIAction(title: attribute.title, image: attribute.image, state: state, handler: handler)
        }

        #if targetEnvironment(macCatalyst)
        filterButtonCustomButton.menu = UIMenu(children: actions)
        #else
        filterButton.menu = UIMenu(children: actions)
        #endif
    }

    private func updateFilterButton(isActive: Bool) {
        let image: UIImage

        if isActive {
            image = Asset.symbol(.line3HorizontalDecreaseCircleFill, scale: .large)
        } else {
            image = Asset.symbol(.line3HorizontalDecreaseCircle, scale: .large)
        }

        #if targetEnvironment(macCatalyst)
        filterButtonCustomButton.setImage(image, for: .normal)
        #else
        filterButton.image = image
        #endif
    }

    private func canSelectCell(at indexPath: IndexPath) -> Bool {
        guard indexPath.row == .zero else { return false }
        return sections[indexPath.section].items.count == 1
    }

    private func headerView(for section: Int) -> UIView? {
        let section = sections[section]
        guard let title = section.title,
              let view = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: PlayerSectionHeaderView.reusdeIdentifier
              ) as? PlayerSectionHeaderView else { return nil }
        view.setup(
            title: title,
            isDownloadEnabled: !section.isDownloaded,
            shouldshowButton: viewModel.shouldShowButtonInSectionHeaders
        )
        view.downloadAction = self.actionTrigger { self.viewModel.downloadEpisodes(for: section) }
        view.deleteAction = self.actionTrigger { self.viewModel.deleteEpisodes(for: section) }
        return view
    }

    private func updateEmptyState(isEmpty: Bool) {
        tableView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
    }

    private func contextMenuConfiguration(for indexPath: IndexPath) -> UIContextMenuConfiguration? {
        guard case let .info(episode, _, _, _) = sections[indexPath.section].items[indexPath.row],
              let imageURL = episode.imageURL else { return nil }
        let previewScreen = ImagePreviewScreen(imageURL: imageURL)
        return UIContextMenuConfiguration(identifier: episode.id as NSCopying, previewProvider: { previewScreen })
    }

    private func targetedContextPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String,
              let index = sections.firstIndex(where: { $0.episode.id == identifier }),
              let previewable = tableView.cellForRow(at: IndexPath(row: .zero, section: index)) as? Previewable else {
            return nil
        }
        return previewable.targetView
    }

    private func getLeftBarButtonItems(isWatchButtonVisible: Bool) -> [UIBarButtonItem] {
        isWatchButtonVisible ? [searchButton, watchButton] : [searchButton]
    }

    private func updateLeftBarButtonItems(isWatchButtonVisible: Bool) {
        navigationItem.leftBarButtonItems = getLeftBarButtonItems(isWatchButtonVisible: isWatchButtonVisible)
    }
}

// MARK: - UITableViewDelegate methods

extension PlayerScreen: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        canSelectCell(at: indexPath)
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        canSelectCell(at: indexPath) ? indexPath : nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.openedEpisodeID = sections[indexPath.section].episodeID
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        headerView(for: section)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard sections.indices.contains(section) else { return .zero }
        return sections[section].title == nil ? .zero : PlayerSectionHeaderView.Constant.height
    }

    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        contextMenuConfiguration(for: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration)
    -> UITargetedPreview? {
        targetedContextPreview(for: configuration)
    }
}

// MARK: - UISearchResultsUpdating methods

extension PlayerScreen: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let keyword = searchController.searchBar.text else { return viewModel.searchKeyword = nil }
        viewModel.searchKeyword = keyword.isEmpty ? nil : keyword
    }
}

// MARK: - UISearchBarDelegate methods

extension PlayerScreen: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.searchKeyword = nil
    }
}

extension PlayerScreen: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }
}
// swiftlint:enable file_length
