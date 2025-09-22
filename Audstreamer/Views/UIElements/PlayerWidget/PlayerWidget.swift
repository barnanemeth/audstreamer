//
//  PlayerWidget.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 18..
//

import UIKit
import Combine

import SkeletonView

// swiftlint:disable file_length
final class PlayerWidget: UIVisualEffectView {

    // MARK: Constants

    private enum Constant {
        static let playPauseButtonScaleFactor: CGFloat = 1.3
        static let remotePlayButtonSize: CGFloat = 32
        static let defaultElapsedText = "00:00:00"
        static let defaultRemainingText = "-00:00:00"
    }

    // MARK: UI

    private let remotePlayContainerView = UIView()
    private let remoteDeviceNameLabel = UILabel()
    private let titleLabel = UILabel()
    private let remotePlayButton = BadgeButton()
    private let buttonsStackView = UIStackView()
    private let playPauseButton = BaseButton()
    private let skipBackwardButton = BaseButton()
    private let skipForwardButton = BaseButton()
    private let slider = UISlider()
    private let elapsedTimeLabel = UILabel()
    private let remainingTimeLabel = UILabel()

    // MARK: Properties

    let viewModel = PlayerWidgetViewModel()
    var titleTapAction: CocoaAction? {
        get { titleTapGestureRecognizer.action }
        set { titleTapGestureRecognizer.action = newValue }
    }
    var remotePlayButtonTap: CocoaAction? {
        get { remotePlayButton.action }
        set { remotePlayButton.action = newValue }
    }
    var remotePlaySourceView: UIView { remotePlayButton }

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private let titleTapGestureRecognizer = TapGestureRecognizer()
    private var isSliderHighlighted: AnyPublisher<Bool, Never> {
        viewModel.$isSliderHighlighted
            .flatMap { Just($0).delay(for: !$0 ? 1 : .zero, scheduler: DispatchQueue.main) }
            .eraseToAnyPublisher()
    }

    // MARK: Init

    init() {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Lifecycle

extension PlayerWidget {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard superview != nil else { return }

        setupView()
        setupBindings()
    }
}

// MARK: - Setups

extension PlayerWidget {
    private func setupView() {
        layer.cornerRadius = 10
        clipsToBounds = true

        setupRemotePlayContainerView()
        setupRemoteDeviceNameLabel()
        setupRemotePlayButton()
        setupTitleLabel()
        setupButtonsStackView()
        setupSkipBackwardButton()
        setupPlayPauseButton()
        setupSkipForwardButton()
        setupSlider()
        setupElapsedTimeLabel()
        setupRemainingTimeLabel()
    }

    private func setupRemotePlayContainerView() {
        remotePlayContainerView.backgroundColor = Asset.Colors.primary.color
        remotePlayContainerView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(remotePlayContainerView)

        NSLayoutConstraint.activate([
            remotePlayContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            remotePlayContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            remotePlayContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            remotePlayContainerView.heightAnchor.constraint(equalToConstant: 22)
        ])

        UIView.animate(
            withDuration: 1.5,
            delay: .zero,
            options: [.autoreverse, .curveLinear, .repeat],
            animations: { self.remotePlayContainerView.backgroundColor = Asset.Colors.secondary.color }
        )
    }

    private func setupRemoteDeviceNameLabel() {
        remoteDeviceNameLabel.textAlignment = .center
        remoteDeviceNameLabel.numberOfLines = 1
        remoteDeviceNameLabel.textColor = Asset.Colors.white.color
        remoteDeviceNameLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        remoteDeviceNameLabel.translatesAutoresizingMaskIntoConstraints = false

        remotePlayContainerView.addSubview(remoteDeviceNameLabel)

        NSLayoutConstraint.activate([
            remoteDeviceNameLabel.centerYAnchor.constraint(equalTo: remotePlayContainerView.centerYAnchor),
            remoteDeviceNameLabel.leadingAnchor.constraint(
                equalTo: remotePlayContainerView.leadingAnchor,
                constant: 8
            ),
            remoteDeviceNameLabel.trailingAnchor.constraint(
                equalTo: remotePlayContainerView.trailingAnchor,
                constant: -8
            )
        ])
    }

    private func setupRemotePlayButton() {
        remotePlayButton.tintColor = Asset.Colors.primary.color
        remotePlayButton.setImage(Asset.Images.airplay.image, for: .normal)
        remotePlayButton.badgeTextColor = Asset.Colors.white.color
        remotePlayButton.badgeBackgroundColor = Asset.Colors.primary.color
        remotePlayButton.badgeFont = UIFont.systemFont(ofSize: 8, weight: .semibold)
        remotePlayButton.badgeRadius = 7
        remotePlayButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(remotePlayButton)

        NSLayoutConstraint.activate([
            remotePlayButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            remotePlayButton.widthAnchor.constraint(equalToConstant: Constant.remotePlayButtonSize),
            remotePlayButton.heightAnchor.constraint(equalToConstant: Constant.remotePlayButtonSize)
        ])
    }

    private func setupTitleLabel() {
        titleLabel.numberOfLines = .zero
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = Asset.Colors.label.color
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(titleTapGestureRecognizer)
        titleLabel.text = L10n.mainTitle
        titleLabel.isSkeletonable = true
        titleLabel.lastLineFillPercent = 80
        titleLabel.linesCornerRadius = 6
        titleLabel.skeletonLineSpacing = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: remotePlayContainerView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: remotePlayButton.leadingAnchor, constant: -8),
            remotePlayButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func setupButtonsStackView() {
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 8
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.alignment = .center
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(buttonsStackView)

        NSLayoutConstraint.activate([
            buttonsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            buttonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 26),
            buttonsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -26),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupSkipBackwardButton() {
        skipBackwardButton.tintColor = Asset.Colors.primary.color
        skipBackwardButton.setImage(Asset.Images.skipBackward.image, for: .normal)

        buttonsStackView.addArrangedSubview(skipBackwardButton)
    }

    private func setupPlayPauseButton() {
        playPauseButton.tintColor = Asset.Colors.primary.color
        playPauseButton.setImage(Asset.Images.play.image, for: .normal)

        buttonsStackView.addArrangedSubview(playPauseButton)

        playPauseButton.transform = CGAffineTransform(
            scaleX: Constant.playPauseButtonScaleFactor,
            y: Constant.playPauseButtonScaleFactor
        )
    }

    private func setupSkipForwardButton() {
        skipForwardButton.tintColor = Asset.Colors.primary.color
        skipForwardButton.setImage(Asset.Images.skipForward.image, for: .normal)

        buttonsStackView.addArrangedSubview(skipForwardButton)
    }

    private func setupSlider() {
        slider.tintColor = Asset.Colors.primary.color
        slider.isSkeletonable = true
        slider.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(slider)

        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 2),
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            slider.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupElapsedTimeLabel() {
        elapsedTimeLabel.numberOfLines = 1
        elapsedTimeLabel.textAlignment = .left
        elapsedTimeLabel.text = Constant.defaultElapsedText
        elapsedTimeLabel.textColor = Asset.Colors.labelSecondary.color
        elapsedTimeLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        elapsedTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(elapsedTimeLabel)

        NSLayoutConstraint.activate([
            elapsedTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 4),
            elapsedTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            elapsedTimeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    private func setupRemainingTimeLabel() {
        remainingTimeLabel.numberOfLines = 1
        remainingTimeLabel.textAlignment = .right
        remainingTimeLabel.text = Constant.defaultRemainingText
        remainingTimeLabel.textColor = Asset.Colors.labelSecondary.color
        remainingTimeLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        remainingTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(remainingTimeLabel)

        NSLayoutConstraint.activate([
            remainingTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 4),
            remainingTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            remainingTimeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    private func setupBindings() {
        viewModel.isEnabled
            .sink { [unowned self] in self.updateEnabledState($0) }
            .store(in: &cancellables)

        viewModel.$isLoading
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.updateLoadingState($0) }
            .store(in: &cancellables)

        viewModel.title
            .compactMap { $0 }
            .assign(to: \.text, on: titleLabel, ownership: .unowned)
            .store(in: &cancellables)

        viewModel.isPlaying
            .sink { [unowned self] in self.updatePlayPauseButton(isPlaying: $0) }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.currentProgress, isSliderHighlighted)
            .filter { !$1 }
            .map { $0.0 }
            .sink { [unowned self] in self.slider.setValue($0, animated: false) }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.elapsedText, viewModel.remainingText)
            .sink { [unowned self] elapsed, remaining in
                self.elapsedTimeLabel.text = elapsed
                self.remainingTimeLabel.text = remaining
            }
            .store(in: &cancellables)

        slider.publisher(for: \.value)
            .dropFirst()
            .assign(to: \.currentSliderValue, on: viewModel, ownership: .unowned)
            .store(in: &cancellables)

        slider.publisher(for: \.isHighlighted)
            .dropFirst()
            .removeDuplicates()
            .assign(to: \.isSliderHighlighted, on: viewModel, ownership: .unowned)
            .store(in: &cancellables)

        viewModel.activeDevicesCount
            .sink { [unowned self] in self.updateRemotePlayButton(by: $0) }
            .store(in: &cancellables)

        viewModel.currentActiveDevice
            .sink { [unowned self] in self.updateRemotePlayView(by: $0) }
            .store(in: &cancellables)

        playPauseButton.action = viewModel.playPauseAction
        skipBackwardButton.action = viewModel.skipBackwardAction
        skipForwardButton.action = viewModel.skipForwardAction
    }
}

// MARK: - Helpers

extension PlayerWidget {
    private func updateEnabledState(_ isEnabled: Bool) {
        self.playPauseButton.isEnabled = isEnabled
        self.slider.isEnabled = isEnabled
        self.playPauseButton.isEnabled = isEnabled
        self.skipBackwardButton.isEnabled = isEnabled
        self.skipForwardButton.isEnabled = isEnabled
    }

    private func updateLoadingState(_ isLoading: Bool) {
        playPauseButton.isEnabled = !isLoading
        skipBackwardButton.isEnabled = !isLoading
        skipForwardButton.isEnabled = !isLoading
        slider.isEnabled = !isLoading
        if isLoading {
            #if !targetEnvironment(macCatalyst)
            slider.thumbTintColor = .clear
            slider.maximumTrackTintColor = Asset.Colors.primary.color
            #endif

            slider.value = .zero
            elapsedTimeLabel.text = Constant.defaultElapsedText
            remainingTimeLabel.text = Constant.defaultRemainingText

            let gradient = SkeletonGradient(baseColor: Asset.Colors.primary.color.withAlphaComponent(0.3))
            titleLabel.showAnimatedGradientSkeleton(
                usingGradient: gradient,
                animation: nil,
                transition: .crossDissolve(0.3)
            )
        } else {
            #if !targetEnvironment(macCatalyst)
            slider.thumbTintColor = nil
            slider.maximumTrackTintColor = nil
            #endif

            titleLabel.hideSkeleton()
        }
    }

    private func updatePlayPauseButton(isPlaying: Bool) {
        let image = isPlaying ? Asset.Images.pause.image : Asset.Images.play.image
        playPauseButton.setImage(image, for: .normal)
    }

    private func updateRemotePlayButton(by activeDevicesCount: Int) {
        if activeDevicesCount > 1 {
            remotePlayButton.badgeValue = activeDevicesCount.description
            remotePlayButton.isEnabled = true
            UIView.animateKeyframes(withDuration: 0.5, delay: .zero) {
                UIView.addKeyframe(withRelativeStartTime: .zero, relativeDuration: 0.5) {
                    self.remotePlayButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.remotePlayButton.transform = CGAffineTransform.identity
                }
            }
        } else {
            remotePlayButton.badgeValue = nil
            remotePlayButton.isEnabled = false
        }
    }

    private func updateRemotePlayView(by activeDevice: Device?) {
        guard let device = activeDevice else {
            remoteDeviceNameLabel.attributedText = nil
            remotePlayContainerView.isHidden = true
            return
        }
        if DeviceHelper.isDeviceIDCurrent(activeDevice?.id) {
            remoteDeviceNameLabel.attributedText = nil
            remotePlayContainerView.isHidden = true
        } else {
            remoteDeviceNameLabel.attributedText = getDeviceNameText(for: device)
            remotePlayContainerView.isHidden = false
        }
    }

    private func getDeviceNameText(for device: Device) -> NSAttributedString {
        let deviceName = device.name
        let text = L10n.listeningOn(deviceName)
        let attributedString = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: Asset.Colors.white.color
            ]
        )
        let range = NSString(string: text).range(of: deviceName)
        attributedString.addAttributes([.font: UIFont.systemFont(ofSize: 11, weight: .bold)], range: range)
        return attributedString
    }
}
// swiftlint:enable file_length
