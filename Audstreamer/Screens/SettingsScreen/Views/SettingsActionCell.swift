//
//  SettingsActionCell.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 16..
//

import UIKit

final class SettingsActionCell: UITableViewCell {

    // MARK: Constants

    private enum Constant {
        #if targetEnvironment(macCatalyst)
        static let fontSize: CGFloat = 12
        #else
        static let fontSize: CGFloat = 16
        #endif
    }

    // MARK: UI

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

extension SettingsActionCell {
    func setup(title: String, isDestructive: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isDestructive ? Asset.Colors.error.color : Asset.Colors.label.color
    }
}

// MARK: - Setups

extension SettingsActionCell {
    private func setupCell() {
        setupTitleLabel()
    }

    private func setupTitleLabel() {
        titleLabel.font = UIFont.systemFont(ofSize: Constant.fontSize)
        titleLabel.textColor = Asset.Colors.label.color
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
