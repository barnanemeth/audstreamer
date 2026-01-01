//
//  Slider.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 13..
//

import SwiftUI

struct Slider: View {
    
    // MARK: Properties

    @Binding var value: Float
    let onHighlightChanged: (Bool) -> Void

    // MARK: Private properties

    @State private var isHighlighted = false

    // MARK: UI

    var body: some View {
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
