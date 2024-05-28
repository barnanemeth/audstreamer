//
//  SettingsSocketInfoCell.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 16..
//

import UIKit

final class SettingsSocketInfoCell: UITableViewCell {

    // MARK: Constants

    private enum Constant {
        #if targetEnvironment(macCatalyst)
        static let fontSize: CGFloat = 12
        #else
        static let fontSize: CGFloat = 16
        #endif
        static let statusImageSize = CGSize(width: 12, height: 12)
    }

    // MARK: UI

    private let statusImageView = UIImageView(image: Asset.symbol(.circleFill))
    private let titleLabel = UILabel()

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupCell()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Public methods

extension SettingsSocketInfoCell {
    func setup(with status: SocketStatus) {
        let title: String
        let color: UIColor

        switch status {
        case .disconnected:
            title = L10n.disconnected
            color = Asset.Colors.error.color
        case .pending:
            title = L10n.pending
            color = Asset.Colors.warning.color
        case .connected:
            title = L10n.connected
            color = Asset.Colors.success.color
        }

        titleLabel.text = title
        statusImageView.tintColor = color
    }
}

// MARK: - Setups

extension SettingsSocketInfoCell {
    private func setupCell() {
        setupStatusImageView()
        setupTitleLabel()
    }

    private func setupStatusImageView() {
        statusImageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(statusImageView)

        NSLayoutConstraint.activate([
            statusImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            statusImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusImageView.widthAnchor.constraint(equalToConstant: Constant.statusImageSize.width),
            statusImageView.heightAnchor.constraint(equalToConstant: Constant.statusImageSize.height)
        ])
    }

    private func setupTitleLabel() {
        titleLabel.font = UIFont.systemFont(ofSize: Constant.fontSize)
        titleLabel.textColor = Asset.Colors.label.color
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: statusImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
