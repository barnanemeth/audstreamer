//
//  FileTransferWidget.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 01/11/2023.
//

import UIKit
import Combine

import Lottie

final class FileTransferWidget: UIView {

    // MARK: Constants

    private enum Constant {
        static let height: CGFloat = 60
        static let fallbackWidth: CGFloat = 460
        static let closedPositionConstraintConstant = -height - 160
        static let openedPositionConstraintConstant: CGFloat = 16
        static let animationDuration: TimeInterval = 0.5
        static let animationSpringDamping: CGFloat = 0.5
        static let finishedAnimationFrame: CGFloat = 0.85
        static let errorDelay: TimeInterval = 1.2
    }

    // MARK: UI

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

    // MARK: Properties

    let viewModel = FileTransferWidgetViewModel()

    // MARK: Private properties

    private weak var parentView: UIView?
    private var cancellables = Set<AnyCancellable>()
    private var isOpened = false {
        didSet { isHidden = !isOpened }
    }
    private var topConstraint: NSLayoutConstraint?
    private var width: CGFloat {
        min(UIScreen.main.bounds.width * 0.8, Constant.fallbackWidth)
    }

    // MARK: Init

    init() {
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Lifecycle

extension FileTransferWidget {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard superview != nil else { return }

        setupView()
        setupBindings()
    }
}

// MARK: - Public methods

extension FileTransferWidget {
    func setup(with parentView: UIView?) {
        self.parentView = parentView
        parentView?.addSubview(self)
    }
}

// MARK: - Setups

extension FileTransferWidget {
    private func setupView() {
        guard let parentView = parentView else { return }

        backgroundColor = Asset.Colors.background.color
        isHidden = !isOpened
        translatesAutoresizingMaskIntoConstraints = false

        setupLayer()

        let topConstraint = topAnchor.constraint(
            equalTo: parentView.safeAreaLayoutGuide.topAnchor,
            constant: Constant.closedPositionConstraintConstant
        )
        self.topConstraint = topConstraint
        NSLayoutConstraint.activate([
            topConstraint,
            heightAnchor.constraint(equalToConstant: Constant.height),
            widthAnchor.constraint(equalToConstant: width),
            centerXAnchor.constraint(equalTo: parentView.centerXAnchor)
        ])

        setupProgressIndicatorView()
        setupTitleLabel()
        setupSubtitleLabel()
    }

    private func setupLayer() {
        layer.cornerRadius = Constant.height / 2
        layer.shadowColor = Asset.Colors.shadow.color.cgColor
        layer.shadowOpacity = 0.7
        layer.shadowOffset = .zero
        layer.shadowRadius = 10
    }

    private func setupProgressIndicatorView() {
        progressIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(progressIndicatorView)

        NSLayoutConstraint.activate([
            progressIndicatorView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            progressIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            progressIndicatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .zero),
            progressIndicatorView.widthAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    private func setupTitleLabel() {
        titleLabel.text = L10n.transferring
        titleLabel.textColor = Asset.Colors.label.color
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: progressIndicatorView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6)
        ])
    }

    private func setupSubtitleLabel() {
        subtitleLabel.textColor = Asset.Colors.label.color
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.numberOfLines = .zero
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: progressIndicatorView.trailingAnchor, constant: 8),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6)
        ])
    }

    private func setupBindings() {
        viewModel.$isOpened
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] isOpened in
                if isOpened {
                    self.open()
                } else {
                    self.close()
                }
            }
            .store(in: &cancellables)

        viewModel.state
            .receive(on: DispatchQueue.main)
            .unwrap()
            .sink { [unowned self] in self.update(with: $0) { self.viewModel.isOpened = false } }
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension FileTransferWidget {
    private func update(with event: FileTransferWidgetState, animationCompletion: @escaping (() -> Void)) {
        switch event {
        case let .inProgress(aggregatedProgress):
            titleLabel.text = L10n.transferring
            updateSubtitleText(aggregatedProgress: aggregatedProgress)
            progressIndicatorView.currentProgress = aggregatedProgress.progress * Constant.finishedAnimationFrame
        case let .finished(aggregatedProgress):
            updateSubtitleText(aggregatedProgress: aggregatedProgress)
            progressIndicatorView.play(
                fromProgress: Constant.finishedAnimationFrame,
                toProgress: 1,
                completion: { _ in animationCompletion() }
            )
        }
    }

    private func animate(animations: @escaping (() -> Void), completion: @escaping (() -> Void)) {
        UIView.animate(
            withDuration: Constant.animationDuration,
            delay: .zero,
            usingSpringWithDamping: Constant.animationSpringDamping,
            initialSpringVelocity: .zero,
            options: .curveEaseInOut,
            animations: animations,
            completion: { _ in completion() }
        )
    }

    private func open() {
        guard !isOpened else { return }
        isHidden = false
        animate(
            animations: {
                self.topConstraint?.constant = Constant.openedPositionConstraintConstant
                self.parentView?.layoutIfNeeded()
            }, completion: { [unowned self] in self.isOpened = true }
        )
    }

    private func close() {
        guard isOpened else { return }
        animate(
            animations: { [unowned self] in
                self.topConstraint?.constant = Constant.closedPositionConstraintConstant
                self.parentView?.layoutIfNeeded()
            },
            completion: { [unowned self] in self.isOpened = false }
        )
    }

    private func updateSubtitleText(aggregatedProgress: FileTransferAggregatedProgress) {
        if aggregatedProgress.isFinished {
            subtitleLabel.text = L10n.transferringEpisodesCountPercentage(aggregatedProgress.numberOfItems, 100)
        } else {
            let percentage = Int(aggregatedProgress.progress * 100)
            subtitleLabel.text = L10n.transferringEpisodesCountPercentage(aggregatedProgress.numberOfItems, percentage)
        }
    }
}
