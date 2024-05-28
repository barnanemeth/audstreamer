//
//  EmptyStateView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 28..
//

import UIKit

final class EmptyStateView: UIView {

    // MARK: Constants

    private enum Constant {
        static let imageSize: CGFloat = 74
    }

    // MARK: UI

    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    // MARK: Private properties

    private let image: UIImage?
    private let title: String?

    // MARK: Init

    init(image: UIImage?, title: String?, tintColor: UIColor = Asset.Colors.primary.color) {
        self.image = image
        self.title = title

        super.init(frame: .zero)

        self.tintColor = tintColor.withAlphaComponent(0.8)

        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Setups

extension EmptyStateView {
    private func setupView() {
        setupImageView()
        setupTitleLabel()
    }

    private func setupImageView() {
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Constant.imageSize),
            imageView.heightAnchor.constraint(equalToConstant: Constant.imageSize),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    private func setupTitleLabel() {
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = tintColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
}
