//
//  DevicesScreen.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 03. 09..
//

import UIKit
import Combine

final class DevicesScreen: UIViewController, Screen {

    // MARK: Typealiases

    private typealias DataSource = UITableViewDiffableDataSource<Int, Device>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Int, Device>

    // MARK: Constants

    private enum Constant {
        static let height: CGFloat = 240
        static let defaultWidth: CGFloat = 280
        static let widthRatio: CGFloat = 0.7
    }

    // MARK: Screen

    @Injected var viewModel: DevicesScreenViewModel

    // MARK: UI

    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var devices = [Device]()
    private lazy var dataSource: DataSource = {
        DataSource(
            tableView: tableView,
            cellProvider: { [unowned self] in self.dequeueCell(from: $0, with: $1, for: $2) }
        )
    }()
    private var contentSize: CGSize {
        let keyWindow: UIWindow = Resolver.resolve()
        let width = min(keyWindow.bounds.width * Constant.widthRatio, Constant.defaultWidth)
        return CGSize(width: width, height: Constant.height)
    }
}

// MARK: - Lifecycle

extension DevicesScreen {
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = contentSize

        setupUI()
        setupBindings()
    }
}

// MARK: - Setups

extension DevicesScreen {
    private func setupUI() {
        setupTableView()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.contentInset = UIEdgeInsets(top: 16, left: .zero, bottom: 16, right: .zero)
        tableView.separatorInset = UIEdgeInsets(top: .zero, left: 16, bottom: .zero, right: 32)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(DeviceCell.self, forCellReuseIdentifier: DeviceCell.reusdeIdentifier)

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBindings() {
        Publishers.CombineLatest(viewModel.devices, viewModel.activeDevice)
            .handleEvents(receiveOutput: { [unowned self] in self.devices = $0.0 })
            .sink { [unowned self] in self.update(with: $0, activeDeviceID: $1) }
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension DevicesScreen {
    private func update(with devices: [Device], activeDeviceID: String?) {
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(devices)
        let animate = dataSource.snapshot().numberOfItems > .zero
        dataSource.apply(snapshot, animatingDifferences: animate, completion: { [unowned self] in
            self.selectCell(for: activeDeviceID)
        })
    }

    private func dequeueCell(from tableView: UITableView,
                             with indexPath: IndexPath,
                             for device: Device) -> DeviceCell? {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DeviceCell.reusdeIdentifier,
            for: indexPath) as? DeviceCell else { return nil }
        cell.setup(with: device)
        return cell
    }
}

// MARK: - Helpers

extension DevicesScreen {
    private func selectCell(for deviceID: String?) {
        guard let rowIndex = devices.firstIndex(where: { $0.id == deviceID }) else { return }
        let indexPath = IndexPath(row: rowIndex, section: .zero)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
}

// MARK: - UITableViewDelegate methods

extension DevicesScreen: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.setActiveDeviceID(devices[indexPath.row].id)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIResponder methods

extension DevicesScreen {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss(animated: true, completion: nil)
    }
}
