//
//  DownloadsScreen.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 30..
//

import UIKit
import Combine

final class DownloadsScreen: BaseHostingScreen<DownloadsView> { }

//final class DownloadsScreen: UIViewController, Screen {
//
//    // MARK: Typealiases
//
//    private typealias DataSource = UITableViewDiffableDataSource<Int, DownloadingCellItem>
//    private typealias Snapshot = NSDiffableDataSourceSnapshot<Int, DownloadingCellItem>
//
//    // MARK: Constants
//
//    private enum Constant {
//        static let rowHeight: CGFloat = 62
//    }
//
//    // MARK: UI
//
//    private let tableView = UITableView(frame: .zero, style: .grouped)
//    private lazy var closeButton: UIBarButtonItem = {
//        UIBarButtonItem(
//            image: Asset.symbol(.xmark, scale: .large),
//            primaryAction: UIAction(handler: { [unowned self] _ in self.dismiss(animated: true) })
//        )
//    }()
//    private let emptyStateView = EmptyStateView(
//        image: Asset.symbol(.checkmarkCircle, scale: .large),
//        title: L10n.allDownloadsCompleted,
//        tintColor: Asset.Colors.success.color
//    )
//
//    // MARK: Screen
//
//    @Injected var viewModel: DownloadsScreenViewModel
//
//    // MARK: Private properties
//
//    private var cancellables = Set<AnyCancellable>()
//    private var items = [DownloadingCellItem]()
//    private lazy var dataSource: DataSource = {
//        DataSource(
//            tableView: tableView,
//            cellProvider: { [unowned self] in self.dequeueDownloadingCell(from: $0, with: $1, for: $2) }
//        )
//    }()
//}
//
//// MARK: - Lifecycle
//
//extension DownloadsScreen {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        setupUI()
//        setupBindings()
//    }
//}
//
//// MARK: - Setups
//
//extension DownloadsScreen {
//    private func setupUI() {
//        view.backgroundColor = UIColor.systemGroupedBackground
//
//        setupNavigationItem()
//        setupCloseButton()
//        setupTableView()
//        setupEmptyStateView()
//    }
//
//    private func setupNavigationItem() {
//        let appearance = UINavigationBarAppearance()
//        navigationItem.standardAppearance = appearance
//        navigationItem.scrollEdgeAppearance = appearance
//
//        title = L10n.downloads
//    }
//
//    private func setupCloseButton() {
//        navigationItem.leftBarButtonItem = closeButton
//    }
//
//    private func setupTableView() {
//        tableView.delegate = self
//        tableView.allowsSelection = false
//        tableView.rowHeight = Constant.rowHeight
//        tableView.estimatedRowHeight = Constant.rowHeight
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//
//        tableView.register(DownloadingCell.self, forCellReuseIdentifier: DownloadingCell.reusdeIdentifier)
//
//        view.addSubview(tableView)
//
//        NSLayoutConstraint.activate([
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//
//    private func setupEmptyStateView() {
//        emptyStateView.isHidden = true
//        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
//
//        view.addSubview(emptyStateView)
//
//        NSLayoutConstraint.activate([
//            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//
//    private func setupBindings() {
//        viewModel.$items
//            .receive(on: DispatchQueue.main)
//            .sink { [unowned self] in self.update(with: $0) }
//            .store(in: &cancellables)
//
//        viewModel.isEmpty
//            .receive(on: DispatchQueue.main)
//            .sink { [unowned self] in self.updateEmptyState(isEmpty: $0) }
//            .store(in: &cancellables)
//    }
//}
//
//// MARK: - Helpers
//
//extension DownloadsScreen {
//    private func update(with items: [DownloadingCellItem]) {
//        self.items = items
//
//        var snapshot = Snapshot()
//
//        snapshot.appendSections([.zero])
//        snapshot.appendItems(items)
//
//        let shouldAnimate = dataSource.snapshot().numberOfItems != snapshot.numberOfItems
//
//        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
//    }
//
//    private func dequeueDownloadingCell(from tableView: UITableView,
//                                        with indexPath: IndexPath,
//                                        for item: DownloadingCellItem) -> DownloadingCell? {
//        guard let cell = tableView.dequeueReusableCell(
//            withIdentifier: DownloadingCell.reusdeIdentifier,
//            for: indexPath
//        ) as? DownloadingCell else { return nil }
//        cell.setup(with: item)
//        return cell
//    }
//
//    private func updateEmptyState(isEmpty: Bool) {
//        tableView.isHidden = isEmpty
//        emptyStateView.isHidden = !isEmpty
//    }
//
//    private func swipeActions(for item: DownloadingCellItem) -> [UIContextualAction] {
//        let pauseResumeAction: UIContextualAction
//        if item.isPaused {
//            let resumeAction = UIContextualAction(
//                style: .normal,
//                title: nil,
//                handler: { [unowned self] in self.viewModel.resume(item.item, completion: $2) }
//            )
//            resumeAction.image = Asset.symbol(.playFill)
//            resumeAction.backgroundColor = Asset.Colors.success.color
//
//            pauseResumeAction = resumeAction
//        } else {
//            let pauseAction = UIContextualAction(
//                style: .normal,
//                title: nil,
//                handler: { [unowned self] in self.viewModel.pause(item.item, completion: $2) }
//            )
//            pauseAction.image = Asset.symbol(.pauseFill)
//            pauseAction.backgroundColor = Asset.Colors.warning.color
//
//            pauseResumeAction = pauseAction
//        }
//
//        let cancelAction = UIContextualAction(
//            style: .destructive,
//            title: nil,
//            handler: { [unowned self] in self.viewModel.cancel(item.item, completion: $2) }
//        )
//        cancelAction.image = Asset.symbol(.stopFill)
//        cancelAction.backgroundColor = Asset.Colors.error.color
//
//        return [pauseResumeAction, cancelAction]
//    }
//}
//
//// MARK: - UITablewViewDelegate methods
//
//extension DownloadsScreen: UITableViewDelegate {
//    func tableView(_ tableView: UITableView,
//                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        UISwipeActionsConfiguration(actions: swipeActions(for: items[indexPath.row]))
//    }
//}
