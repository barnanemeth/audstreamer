//
//  PlayerSectionHeaderView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 19..
//

import UIKit

final class PlayerSectionHeaderView: UITableViewHeaderFooterView {

    // MARK: Constants

    enum Constant {
        static let height: CGFloat = 52
        static let verticalPadding: CGFloat = 4
    }

    // MARK: UI

    private let titleLabel = UILabel()
    private let downloadButton = BaseButton()
    private let deleteButton = BaseButton()

    // MARK: Properties

    var downloadAction: CocoaAction? {
        get { downloadButton.action }
        set { downloadButton.action = newValue }
    }
    var deleteAction: CocoaAction? {
        get { deleteButton.action }
        set { deleteButton.action = newValue }
    }

    // MARK: Private properties

    private var buttonSize: CGFloat {
        Constant.height - (2 * Constant.verticalPadding)
    }

    // MARK: Init

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Public methods

extension PlayerSectionHeaderView {
    func setup(title: String, isDownloadEnabled: Bool, shouldshowButton: Bool) {
        titleLabel.text = title

        let isDownloadButtonVisible = isDownloadEnabled && shouldshowButton
        let isDeleteButtonVisible = !isDownloadEnabled && shouldshowButton

        downloadButton.isHidden = !isDownloadButtonVisible
        deleteButton.isHidden = !isDeleteButtonVisible
    }
}

// MARK: - Setups

extension PlayerSectionHeaderView {
    private func setupView() {
        setupDownloadButton()
        setupDeleteButton()
        setupTitleLabel()
    }

    private func setupDownloadButton() {
        downloadButton.setImage(Asset.symbol(.arrowDownCircleFill, scale: .large), for: .normal)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(downloadButton)

        NSLayoutConstraint.activate([
            downloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            downloadButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: buttonSize),
            downloadButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }

    private func setupDeleteButton() {
        deleteButton.setImage(Asset.symbol(.trashFill, scale: .large), for: .normal)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(deleteButton)

        NSLayoutConstraint.activate([
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: buttonSize),
            deleteButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }

    private func setupTitleLabel() {
        titleLabel.textColor = Asset.Colors.label.color
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalTo: downloadButton.heightAnchor)
        ])
    }
}
