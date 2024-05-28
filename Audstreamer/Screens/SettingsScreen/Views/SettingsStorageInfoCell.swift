//
//  SettingsStorageInfoCell.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 16..
//

import UIKit

final class SettingsStorageInfoCell: UITableViewCell {

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

extension SettingsStorageInfoCell {
    func setup(with downloadSize: Int) {
        titleLabel.attributedText = getText(for: downloadSize)
    }
}

// MARK: - Setups

extension SettingsStorageInfoCell {
    private func setupCell() {
        setupTitleLabel()
    }

    private func setupTitleLabel() {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}

// MARK: - Helpers

extension SettingsStorageInfoCell {
    private func getText(for downloadSize: Int) -> NSAttributedString {
        let downloadSize = NumberFormatterHelper.getFormattedContentSize(from: downloadSize)
        let text = L10n.downloadsSize(downloadSize)
        let attributedString = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: Constant.fontSize, weight: .regular),
                .foregroundColor: Asset.Colors.label.color
            ]
        )
        let range = NSString(string: text).range(of: downloadSize)
        attributedString.addAttributes(
            [.font: UIFont.systemFont(ofSize: Constant.fontSize, weight: .semibold)],
            range: range
        )
        return attributedString
    }
}
