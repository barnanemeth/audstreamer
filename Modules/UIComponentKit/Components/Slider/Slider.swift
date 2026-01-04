//
//  Slider.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 13..
//

import SwiftUI

public struct Slider: View {

    // MARK: Private properties

    @Binding private var value: Float
    private let onHighlightChanged: (Bool) -> Void
    @State private var isHighlighted = false

    // MARK: Init

    public init(value: Binding<Float>, onHighlightChanged: @escaping (Bool) -> Void) {
        self._value = value
        self.onHighlightChanged = onHighlightChanged
        self.isHighlighted = isHighlighted
    }

    // MARK: UI

    public var body: some View {
        SwiftUI.Slider(value: $value, in: 0...1)
            .simultaneousGesture(
                DragGesture(minimumDistance: .zero)
                    .onChanged { _ in
                        guard !isHighlighted else { return }
                        isHighlighted = true
                        onHighlightChanged(true)
                    }
                    .onEnded { _ in
                        guard isHighlighted else { return }
                        isHighlighted = false
                        onHighlightChanged(false)
                    }
            )
    }
}
