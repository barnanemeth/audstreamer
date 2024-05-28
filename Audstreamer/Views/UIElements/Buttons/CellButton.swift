//
//  CellButton.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import UIKit

final class CellButton: BaseButton {

    // MARK: Properties

    override var isHighlighted: Bool {
        didSet { update() }
    }
    var title: String? {
        didSet { setTitle(title, for: .normal) }
    }
    var image: UIImage? {
        didSet { setImage(image, for: .normal) }
    }

    // MARK: Init

    init(title: String? = nil, image: UIImage) {
        self.title = title
        self.image = image

        super.init(frame: .zero)

        setupButton()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Setups

extension CellButton {
    private func setupButton() {
        layer.cornerRadius = 7
        backgroundColor = Asset.Colors.secondary.color
        tintColor = Asset.Colors.white.color
        setTitleColor(Asset.Colors.white.color, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel?.textAlignment = .center
        adjustsImageWhenHighlighted = false
        titleEdgeInsets = UIEdgeInsets(
            top: titleEdgeInsets.top,
            left: 4,
            bottom: titleEdgeInsets.bottom,
            right: titleEdgeInsets.right
        )

        setTitle(title, for: .normal)
        setImage(image, for: .normal)
    }
}

// MARK: - Helpers

extension CellButton {
    private func update() {
        UIView.animate(withDuration: 0.15) {
            self.backgroundColor = self.isHighlighted ? Asset.Colors.primary.color : Asset.Colors.secondary.color
        }
    }
}
