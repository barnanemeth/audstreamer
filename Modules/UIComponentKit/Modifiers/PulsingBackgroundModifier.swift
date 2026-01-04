//
//  PulsingBackgroundModifier.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 30..
//

import SwiftUI

struct PulsingBackground: ViewModifier {
    let from: Color
    let to: Color
    let duration: Double

    @State private var toggle = false

    func body(content: Content) -> some View {
        content
            .background(toggle ? to : from)
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    toggle.toggle()
                }
            }
    }
}

extension View {
    public func pulsingBackground(
        from: Color,
        to: Color,
        duration: Double = 1.5
    ) -> some View {
        modifier(PulsingBackground(from: from, to: to, duration: duration))
    }
}
