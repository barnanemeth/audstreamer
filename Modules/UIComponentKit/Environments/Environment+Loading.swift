//
//  Environment+Loading.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI

public struct LoadingEnvironmentKey: EnvironmentKey {
    public static let defaultValue = false
}

extension EnvironmentValues {
    public var isLoading: Bool {
        get { self[LoadingEnvironmentKey.self] }
        set { self[LoadingEnvironmentKey.self] = newValue }
    }
}
