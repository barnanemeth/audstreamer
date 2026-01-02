//
//  SizeChangedModifier.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 31..
//

import SwiftUI

private struct SizeObserver: UIViewRepresentable {
    var onChange: (CGSize) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = ObserverView()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? ObserverView)?.onChange = onChange
    }

    private final class ObserverView: UIView {
        var onChange: ((CGSize) -> Void)?
        private var lastSize: CGSize = .zero

        override func layoutSubviews() {
            super.layoutSubviews()
            let newSize = bounds.size
            guard newSize != lastSize else { return }
            lastSize = newSize

            // Avoid “state update during layout” edge cases
            DispatchQueue.main.async { [onChange] in
                onChange?(newSize)
            }
        }
    }
}

extension View {
    /// Reliable size changes (works well in interactive sheet detent dragging)
    func onSizeChanged(_ action: @escaping (CGSize) -> Void) -> some View {
        background(SizeObserver(onChange: action))
    }
}
