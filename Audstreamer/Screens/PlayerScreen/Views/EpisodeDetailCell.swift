//
//  EpisodeDetailCell.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import UIKit
import AVFoundation

import SkeletonView

final class EpisodeDetailCell: UITableViewCell {

    // MARK: UI

    private let buttonsStackView = UIStackView()
    private let playButton = CellButton(image: Asset.symbol(.playFill, scale: .large))
    private let linkButton = CellButton(image: Asset.symbol(.link, scale: .large))
    private let favoriteButton = CellButton(image: Asset.symbol(.heartFill, scale: .large))
    private let downloadDeleteButton = CellButton(image: Asset.symbol(.arrowDownCircleFill, scale: .large))
    private let watchButton = CellButton(image: Asset.symbol(.applewatch, scale: .large))
    private let publishDateLabel = UILabel()
    private let durationLabel = UILabel()

    // MARK: Properties

    var playAction: CocoaAction? {
        get { playButton.action }
        set { playButton.action = newValue }
    }
    var linkAction: CocoaAction? {
        get { linkButton.action }
        set { linkButton.action = newValue }
    }
    var downloadDeleteAction: CocoaAction? {
        get { downloadDeleteButton.action }
        set { downloadDeleteButton.action = newValue }
    }
    var favoriteAction: CocoaAction? {
        get { favoriteButton.action }
        set { favoriteButton.action = newValue }
    }
    var watchAction: CocoaAction? {
        get { watchButton.action }
        set { watchButton.action = newValue }
    }

    // MARK: Private properties

    private lazy var datFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Lifecycle

extension EpisodeDetailCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        reset()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        return
    }
}

// MARK: - Setups

extension EpisodeDetailCell {
    private func setupView() {
        setupButtonsStackView()
        setupPlayButton()
//        setupLinkButton()
        setupFavoriteButton()
        setupDonwloadDeleteButton()
        setupWatchButton()
        setupPublishDateLabel()
        setupDurationLabel()
    }

    private func setupButtonsStackView() {
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 16
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(buttonsStackView)

        NSLayoutConstraint.activate([
            buttonsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            buttonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupPlayButton() {
        playButton.translatesAutoresizingMaskIntoConstraints = false

        buttonsStackView.addArrangedSubview(playButton)
    }

    private func setupLinkButton() {
        linkButton.isHidden = true
        linkButton.translatesAutoresizingMaskIntoConstraints = false

        buttonsStackView.addArrangedSubview(linkButton)
    }

    private func setupFavoriteButton() {
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false

        buttonsStackView.addArrangedSubview(favoriteButton)
    }

    private func setupDonwloadDeleteButton() {
        downloadDeleteButton.translatesAutoresizingMaskIntoConstraints = false

        buttonsStackView.addArrangedSubview(downloadDeleteButton)
    }

    private func setupWatchButton() {
        watchButton.isHidden = true
        watchButton.translatesAutoresizingMaskIntoConstraints = false

        buttonsStackView.addArrangedSubview(watchButton)
    }

    private func setupPublishDateLabel() {
        publishDateLabel.textAlignment = .left
        publishDateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        publishDateLabel.textColor = Asset.Colors.label.color
        publishDateLabel.numberOfLines = 2
        publishDateLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(publishDateLabel)

        NSLayoutConstraint.activate([
            publishDateLabel.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 20),
            publishDateLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            publishDateLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    private func setupDurationLabel() {
        durationLabel.textAlignment = .right
        durationLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        durationLabel.textColor = Asset.Colors.label.color
        durationLabel.numberOfLines = 2
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(durationLabel)

        NSLayoutConstraint.activate([
            durationLabel.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 20),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }
}

// MARK: - Public methods

extension EpisodeDetailCell {
    func setup(with episode: EpisodeData, isWatchAvailable: Bool) {
        updateLinkButton(with: episode)
        updateDownloadDeleteButton(with: episode)
        updateFavoriteButton(with: episode)
        updateWatchButton(with: episode)
        publishDateLabel.text = L10n.publishDate(datFormatter.string(from: episode.publishDate))
        durationLabel.text = L10n.duration(Double(episode.duration).secondsToHoursMinutesSecondsString)
        watchButton.isHidden = !isWatchAvailable
    }
}

// MARK: - Helpers

extension EpisodeDetailCell {
    private func updateLinkButton(with episode: EpisodeData) {
        if let linkString = episode.link, URL(string: linkString) != nil {
            linkButton.isHidden = false
        } else {
            linkButton.isHidden = true
        }
    }

    private func updateDownloadDeleteButton(with episode: EpisodeData) {
        let image = episode.isDownloaded ?
            Asset.symbol(.trashFill, scale: .large) :
            Asset.symbol(.arrowDownCircleFill, scale: .large)
        downloadDeleteButton.image = image
    }

    private func updateFavoriteButton(with episode: EpisodeData) {
        let image = episode.isFavourite ?
            Asset.symbol(.heartSlashFill, scale: .large) :
            Asset.symbol(.heartFill, scale: .large)
        favoriteButton.image = image
    }

    private func updateWatchButton(with episode: EpisodeData) {
        let image = episode.isOnWatch ?
            Asset.symbol(.applewatchSlash, scale: .large) :
            Asset.symbol(.applewatch, scale: .large)
        watchButton.image = image
    }

    private func reset() {
        playAction = nil
        favoriteAction = nil

        durationLabel.text = nil
        publishDateLabel.text = nil
    }
}
