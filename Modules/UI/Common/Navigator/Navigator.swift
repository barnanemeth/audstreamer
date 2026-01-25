//
//  Navigator.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2026. 01. 04..
//

import SwiftUI

public protocol NavigatorPublic {
    @MainActor var rootView: AnyView { get }
}

protocol Navigator: NavigatorPublic {
    @MainActor func navigate(to destination: AppNavigationDestination, method: NavigationMethod)
    @MainActor func dismiss()
    @MainActor func pop()
    @MainActor func changeTab(to tab: MainTab)
}
