//
//  EpisodeCell.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import UIKit

import SFSafeSymbols
import Nuke

final class EpisodeInfoCell: UITableViewCell {

    // MARK: Constants

    enum Constant {
        static let minimumHeight: CGFloat = 128
        static let iconSize: CGFloat = 20
        static let thumbnailSize = CGSize(width: 106, height: 60)
        static let playedThresholdSeconds = 10
        static let verticalPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 20
    }

    // MARK: UI

    private let indicatorsStackView = UIStackView()
    private let favoriteIconImageView = UIImageView(image: UIImage(systemSymbol: .heartFill))
    private let downloadedIconImageView = UIImageView(image: UIImage(systemSymbol: .arrowDownCircleFill))
    private let watchIconImageView = UIImageView(image: UIImage(systemSymbol: .applewatch))
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Lifecycle

extension EpisodeInfoCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        favoriteIconImageView.isHidden = true
        downloadedIconImageView.isHidden = true
        progressView.isHidden = true
        thumbnailImageView.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        return
    }
}

// MARK: - Setups

extension EpisodeInfoCell {
    private func setupView() {
        setupIndicatorsStackView()
        setupIndicatorIcons()
        setupThumbnailImageView()
        setupProgressView()
        setupTitleLabel()
    }

    private func setupIndicatorsStackView() {
        indicatorsStackView.axis = .horizontal
        indicatorsStackView.distribution = .fillEqually
        indicatorsStackView.spacing = 8
        indicatorsStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(indicatorsStackView)

        NSLayoutConstraint.activate([
            indicatorsStackView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Constant.verticalPadding
            ),
            indicatorsStackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Constant.horizontalPadding
            ),
            indicatorsStackView.heightAnchor.constraint(equalToConstant: Constant.iconSize)
        ])
    }

    private func setupIndicatorIcons() {
        favoriteIconImageView.contentMode = .scaleAspectFit
        downloadedIconImageView.contentMode = .scaleAspectFit
        watchIconImageView.contentMode = .scaleAspectFit
        favoriteIconImageView.translatesAutoresizingMaskIntoConstraints = false
        downloadedIconImageView.translatesAutoresizingMaskIntoConstraints = false
        watchIconImageView.translatesAutoresizingMaskIntoConstraints = false

        indicatorsStackView.addArrangedSubview(favoriteIconImageView)
        indicatorsStackView.addArrangedSubview(downloadedIconImageView)
        indicatorsStackView.addArrangedSubview(watchIconImageView)

        NSLayoutConstraint.activate([
            favoriteIconImageView.widthAnchor.constraint(equalToConstant: Constant.iconSize),
            downloadedIconImageView.widthAnchor.constraint(equalToConstant: Constant.iconSize),
            watchIconImageView.widthAnchor.constraint(equalToConstant: Constant.iconSize)
        ])
    }

    private func setupThumbnailImageView() {
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 7
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(thumbnailImageView)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constant.verticalPadding),
            thumbnailImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Constant.horizontalPadding
            ),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: Constant.thumbnailSize.width),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: Constant.thumbnailSize.height)
        ])
    }

    private func setupProgressView() {
        progressView.progressTintColor = Asset.Colors.primary.color
        progressView.tintColor = Asset.Colors.primary.color
        progressView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Constant.horizontalPadding
            ),
            progressView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Constant.horizontalPadding
            ),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constant.verticalPadding)
        ])
    }

    private func setupTitleLabel() {
        titleLabel.numberOfLines = .zero
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = Asset.Colors.label.color
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constant.verticalPadding),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: indicatorsStackView.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -8),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Constant.thumbnailSize.height)
        ])
    }
}

// MARK: - Public methods

extension EpisodeInfoCell {
    func setup(with episode: EpisodeData) {
        titleLabel.text = episode.title
        favoriteIconImageView.isHidden = !episode.isFavourite
        downloadedIconImageView.isHidden = !episode.isDownloaded
        watchIconImageView.isHidden = !episode.isOnWatch
        setThumbnail(for: episode)
        updateProgressView(for: episode)
    }
}

// MARK: - Helpers

extension EpisodeInfoCell {
    private func setThumbnail(for episode: EpisodeData) {
        guard let imageString = episode.thumbnail?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let imageURL = URL(string: imageString) else {
            return thumbnailImageView.image = Asset.Images.logoLarge.image
        }
        Nuke.loadImage(with: imageURL, into: thumbnailImageView)
    }

    private func updateProgressView(for episode: EpisodeData) {
        if episode.lastPosition >= Constant.playedThresholdSeconds {
            let progress = Float(episode.lastPosition) / Float(episode.duration)
            progressView.progress = progress
            progressView.isHidden = false
        } else {
            progressView.progress = .zero
            progressView.isHidden = true
        }
    }
}

// MARK: - Previewable

extension EpisodeInfoCell: Previewable {
    var targetView: UITargetedPreview {
        UITargetedPreview(view: thumbnailImageView)
    }
}
