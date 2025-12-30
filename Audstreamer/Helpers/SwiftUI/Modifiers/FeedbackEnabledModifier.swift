//
//  FeedbackEnabledModifier.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 30..
//

import SwiftUI

struct FeedbackEnabledModifier {

    // MARK: Private properties

    private let isFeedbackEnabled: Bool

    // MARK: Init

    init(isFeedbackEnabled: Bool) {
        self.isFeedbackEnabled = isFeedbackEnabled
    }
}

// MARK: - ViewModifier

extension FeedbackEnabledModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.isFeedbackEnabled, isFeedbackEnabled)
    }
}

// MARK: - View

extension View {
    public func feedbackEnabled(_ isEnabled: Bool = true) -> some View {
        modifier(FeedbackEnabledModifier(isFeedbackEnabled: isEnabled))
    }
}
