//
//  DownloadingCell.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 12. 02..
//

import UIKit
import Combine

import Lottie

final class DownloadingCell: UITableViewCell {

    // MARK: Constants

    private enum Constant {
        static let finishedAnimationFrame: CGFloat = 0.85
    }

    // MARK: UI

    private let labelStackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private lazy var progressIndicatorView: LottieAnimationView = {
        let path = Bundle.main.url(forResource: "DownloadAnimation", withExtension: "json")?.path
        guard let path = path else { preconditionFailure("Cannot load resource") }
        let engine = RenderingEngine.coreAnimation
        let option = RenderingEngineOption.specific(engine)
        let config = LottieConfiguration(renderingEngine: option)
        return LottieAnimationView(filePath: path, configuration: config)
    }()
    private let errorImageView = UIImageView(image: Asset.symbol(.xmarkCircle, scale: .large))

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupCell()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Lifecycle

extension DownloadingCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        updateViews(isErrorOccurred: false)
        progressIndicatorView.stop()
        cancellables.removeAll()
    }
}

// MARK: - Public methods

extension DownloadingCell {
    func setup(with item: DownloadingCellItem) {
        titleLabel.text = item.title
        subtitleLabel.text = L10n.downloadQueued
        setupBinding(for: item.eventPublisher)
    }
}

// MARK: - Setups

extension DownloadingCell {
    private func setupCell() {
        setupProgressIndicatorView()
        setupErrorImageView()
        setupLabelStackView()
        setupTitleLabel()
        setupSubtitleLabel()
    }

    private func setupProgressIndicatorView() {
        progressIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(progressIndicatorView)

        NSLayoutConstraint.activate([
            progressIndicatorView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            progressIndicatorView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            progressIndicatorView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            progressIndicatorView.widthAnchor.constraint(equalTo: progressIndicatorView.heightAnchor)
        ])
    }

    private func setupErrorImageView() {
        errorImageView.isHidden = true
        errorImageView.contentMode = .scaleAspectFit
        errorImageView.tintColor = Asset.Colors.error.color
        errorImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(errorImageView)

        NSLayoutConstraint.activate([
            errorImageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            errorImageView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            errorImageView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            errorImageView.widthAnchor.constraint(equalTo: errorImageView.heightAnchor)
        ])
    }

    private func setupLabelStackView() {
        labelStackView.axis = .vertical
        labelStackView.spacing = 4
        labelStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(labelStackView)

        NSLayoutConstraint.activate([
            labelStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            labelStackView.trailingAnchor.constraint(equalTo: progressIndicatorView.leadingAnchor, constant: -8),
            labelStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    private func setupTitleLabel() {
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = Asset.Colors.label.color

        labelStackView.addArrangedSubview(titleLabel)
    }

    private func setupSubtitleLabel() {
        subtitleLabel.numberOfLines = 1
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = Asset.Colors.label.color

        labelStackView.addArrangedSubview(subtitleLabel)
    }
}

// MARK: - Helpers

extension DownloadingCell {
    private func setupBinding(for eventPublisher: AnyPublisher<DownloadEvent, Error>) {
        eventPublisher
            .sink { [unowned self] event in
                switch event {
                case .queued:
                    self.subtitleLabel.text = L10n.downloadQueued
                case let .inProgress(_, progress):
                    let currentProgress = progress.fractionCompleted * Constant.finishedAnimationFrame
                    self.progressIndicatorView.currentProgress = currentProgress
                    self.updateViews(isErrorOccurred: false)
                    self.subtitleLabel.text = L10n.downloadInProgress
                case .finished:
                    self.progressIndicatorView.play(fromProgress: Constant.finishedAnimationFrame, toProgress: 1)
                    self.updateViews(isErrorOccurred: false)
                    self.subtitleLabel.text = L10n.downloadFinished
                case let .error(_, error):
                    self.updateViews(isErrorOccurred: true)
                    self.subtitleLabel.text = L10n.downloadError(error.localizedDescription)
                default:
                    return
                }
            }
            .store(in: &cancellables)
    }

    private func updateViews(isErrorOccurred: Bool) {
        progressIndicatorView.isHidden = isErrorOccurred
        errorImageView.isHidden = !isErrorOccurred
    }
}
