//
//  SettingsFooterView.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 17..
//

import UIKit

final class SettingsFooterView: UIView {

    // MARK: Constants

    private enum Constant {
        static let verticalPadding: CGFloat = 8
        static let logoSize: CGFloat = 52
    }

    // MARK: UI

    private let containerStackView = UIStackView()
    private let logoImageView = UIImageView(image: Asset.Images.logoLarge.image)
    private let versionLabel = UILabel()
    private let copyrightLabel = UILabel()

    // MARK: Init

    init() {
        super.init(frame: .zero)

        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Lifecycle

extension SettingsFooterView {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard let superview = superview else { return }

        let width = superview.bounds.width
        let size = systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))

        if frame.size.height != size.height {
            frame.size.height = size.height
        }
    }
}

// MARK: - Setups

extension SettingsFooterView {
    private func setupView() {
        setupContainerStackView()
        setupLogoImageView()
        setupVersionLabel()
        setupCopyrightLabel()
    }

    private func setupContainerStackView() {
        containerStackView.axis = .vertical
        containerStackView.spacing = 12
        containerStackView.alignment = .center
        containerStackView.layoutMargins = UIEdgeInsets(
            top: Constant.verticalPadding,
            left: .zero,
            bottom: Constant.verticalPadding,
            right: .zero
        )
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerStackView)

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupLogoImageView() {
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        containerStackView.addArrangedSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: Constant.logoSize)
        ])
    }

    private func setupVersionLabel() {
        versionLabel.text = About.versionString
        versionLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        versionLabel.textColor = Asset.Colors.label.color

        containerStackView.addArrangedSubview(versionLabel)
    }

    private func setupCopyrightLabel() {
        copyrightLabel.text = About.copyrightString
        copyrightLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        copyrightLabel.textColor = Asset.Colors.label.color

        containerStackView.addArrangedSubview(copyrightLabel)
    }
}
