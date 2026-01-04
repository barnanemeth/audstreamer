//
//  Environment+FeedbackEnabled.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI

struct FeedbackEnabledEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isFeedbackEnabled: Bool {
        get { self[FeedbackEnabledEnvironmentKey.self] }
        set { self[FeedbackEnabledEnvironmentKey.self] = newValue }
    }
}
