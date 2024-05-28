//
//  SettingsScreen.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import UIKit
import Combine

final class SettingsScreen: UIViewController, Screen {

    // MARK: Typealiases

    private typealias Snapshot = NSDiffableDataSourceSnapshot<SettingsSection, SettingsItem>
    private typealias CellAction = (title: String, isDestructive: Bool)

    // MARK: Screen

    @Injected var viewModel: SettingsScreenViewModel

    // MARK: UI

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private lazy var closeButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: Asset.symbol(.xmark, scale: .large),
            primaryAction: UIAction(handler: { [unowned self] _ in self.dismiss(animated: true) })
        )
    }()
    private let loadingView = UIActivityIndicatorView(style: .medium)

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var sections = [SettingsSection]()
    private lazy var dataSource: SettingsDataSource = {
        SettingsDataSource(
            tableView: tableView,
            cellProvider: { [unowned self] in self.dequeueCell(from: $0, with: $1, for: $2) }
        )
    }()
}

// MARK: - Lifecycle

extension SettingsScreen {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBindings()
    }
}

// MARK: - Setups

extension SettingsScreen {
    private func setupUI() {
        setupNavigationItem()
        setupTableView()
        setupCloseButton()
        setupLoadingView()
        setupFooterView()
    }

    private func setupNavigationItem() {
        let appearance = UINavigationBarAppearance()
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance

        title = L10n.settings
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(
            SettingsStorageInfoCell.self,
            forCellReuseIdentifier: SettingsStorageInfoCell.reusdeIdentifier
        )
        tableView.register(SettingsSocketInfoCell.self, forCellReuseIdentifier: SettingsSocketInfoCell.reusdeIdentifier)
        tableView.register(SettingsActionCell.self, forCellReuseIdentifier: SettingsActionCell.reusdeIdentifier)

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCloseButton() {
        navigationItem.leftBarButtonItem = closeButton
    }

    private func setupLoadingView() {
        loadingView.color = Asset.Colors.primary.color

        let barButtonItem = UIBarButtonItem(customView: loadingView)

        navigationItem.rightBarButtonItem = barButtonItem

        loadingView.startAnimating()
    }

    private func setupFooterView() {
        tableView.tableFooterView = SettingsFooterView()
    }

    private func setupBindings() {
        viewModel.sections
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.update(with: $0) }
            .store(in: &cancellables)

        viewModel.$isLoading
            .sink { [unowned self] isLoading in
                if isLoading {
                    self.loadingView.startAnimating()
                } else {
                    self.loadingView.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.presentErrorAlertAction = Action<Error, Never> { [unowned self] error in
            guard let error = try? error.get() else { return }
            self.showAlert(for: error)
        }

        viewModel.navigateToLoginScreenAction = CocoaAction { [unowned self] in self.navigateToLoginScreen() }
        viewModel.presentDeleteDownloadActionSheetAction = CocoaAction { [unowned self] in
            self.presentActionSheet(
                title: L10n.deleteDownloads,
                message: L10n.deleteDownloadsConfirm,
                confirm: L10n.deleteDownloads,
                action: { self.viewModel.deleteDownloads() }
            )
        }
        viewModel.presentLogoutActionSheetAction = CocoaAction { [unowned self] in
            self.presentActionSheet(
                title: L10n.logout,
                message: L10n.logoutConfirm,
                confirm: L10n.logout,
                action: { self.viewModel.logout() }
            )
        }
    }
}

// MARK: - Helpers

extension SettingsScreen {
    private func update(with sections: [SettingsSection]) {
        self.sections = sections

        let snapshot = sections.reduce(into: Snapshot(), { snapshot, section in
            snapshot.appendSections([section])
            snapshot.appendItems(section.items, toSection: section)
        })
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func dequeueCell(from tableView: UITableView,
                             with indexPath: IndexPath,
                             for item: SettingsItem) -> UITableViewCell? {
        switch item {
        case let .storageInfo(downloadSize):
            return dequeueStorageInfoCell(from: tableView, with: indexPath, downloadSize: downloadSize)
        case .storageAction:
            return dequeueSettingsActionCell(from: tableView, with: indexPath, action: (L10n.deleteDownloads, true))
        case let .socketInfo(status):
            return dequeueSettingsSocketInfoCell(from: tableView, with: indexPath, status: status)
        case let .socketAction(type):
            return dequeueSettingsActionCell(from: tableView, with: indexPath, action: socketAction(for: type))
        case let .accountAction(type):
            return dequeueSettingsActionCell(from: tableView, with: indexPath, action: settingsAction(for: type))
        }
    }

    private func dequeueStorageInfoCell(from tableView: UITableView,
                                        with indexPath: IndexPath,
                                        downloadSize: Int) -> SettingsStorageInfoCell? {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingsStorageInfoCell.reusdeIdentifier,
            for: indexPath
        ) as? SettingsStorageInfoCell else { return nil }
        cell.setup(with: downloadSize)
        return cell
    }

    private func dequeueSettingsSocketInfoCell(from tableView: UITableView,
                                               with indexPath: IndexPath,
                                               status: SocketStatus) -> SettingsSocketInfoCell? {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingsSocketInfoCell.reusdeIdentifier,
            for: indexPath
        ) as? SettingsSocketInfoCell else { return nil }
        cell.setup(with: status)
        return cell
    }

    private func dequeueSettingsActionCell(from tableView: UITableView,
                                           with indexPath: IndexPath,
                                           action: CellAction) -> SettingsActionCell? {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingsActionCell.reusdeIdentifier,
            for: indexPath
        ) as? SettingsActionCell else { return nil }
        cell.setup(title: action.title, isDestructive: action.isDestructive)
        return cell
    }

    private func socketAction(for type: SettingsItem.SocketActionType) -> CellAction {
        switch type {
        case .connect: return (L10n.connect, false)
        case .disconnect: return (L10n.disconnect, false)
        }
    }

    private func settingsAction(for type: SettingsItem.AccountActionType) -> CellAction {
        switch type {
        case .login: return (L10n.logIn, false)
        case .logout: return (L10n.logout, true)
        }
    }

    private func navigateToLoginScreen() {
           let loginScreen: LoginScreen = Resolver.resolve()
           present(loginScreen, animated: true, completion: nil)
       }

    private func presentActionSheet(title: String, message: String, confirm: String, action: @escaping (() -> Void)) {
        #if targetEnvironment(macCatalyst)
        let actionSheet = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        #else
        let actionSheet = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .actionSheet
        )
        #endif
        let confirmAction = UIAlertAction(
            title: confirm,
            style: .destructive,
            handler: { _ in action() }
        )
        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)

        actionSheet.addAction(cancelAction)
        actionSheet.addAction(confirmAction)

        actionSheet.preferredAction = confirmAction

        present(actionSheet, animated: true, completion: nil)
    }

    private func canSelectCell(at indexPath: IndexPath) -> Bool {
        !viewModel.isLoading && sections[indexPath.section].items[indexPath.row].isAction
    }
}

// MARK: - UITableViewDelegate methods

extension SettingsScreen: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        canSelectCell(at: indexPath)
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        canSelectCell(at: indexPath) ? indexPath : nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        viewModel.handleTap(for: item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
