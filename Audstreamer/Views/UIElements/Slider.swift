//
//  Slider.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 13..
//

import UIKit
import Combine

final class Slider: UISlider {

    // MARK: Properties

    var valueChangedPublisher: AnyPublisher<Float, Never> {
        valueChangedSubject.eraseToAnyPublisher()
    }

    // MARK: Private properties

    private let valueChangedSubject = PassthroughSubject<Float, Never>()

    // MARK: Init

    init() {
        super.init(frame: .zero)

        let action = UIAction { [weak self] _ in
            guard let self else { return }
            valueChangedSubject.send(self.value)
        }
        addAction(action, for: .valueChanged)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
