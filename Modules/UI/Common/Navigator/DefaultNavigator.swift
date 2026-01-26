//
//  DefaultNavigator.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 21..
//

import SwiftUI

import Common
import UIComponentKit

internal import NavigatorUI

struct RootView: View {

    let navigator: NavigatorUI.Navigator

    var body: some View {
        ManagedNavigationStack(name: "Root") {
            navigator.mappedNavigationView(for: AppNavigationDestination.root)
                .navigationRoot(navigator)
                .navigationDestination(AppNavigationDestination.self)
        }
    }
}

@MainActor
struct DefaultNavigator {

    // MARK: Private properties

    private let rootNavigator: NavigatorUI.Navigator
    private var currentNavigator: NavigatorUI.Navigator {
        if let current = rootNavigator.current, current.isPresented {
            current
        } else {
            rootNavigator
        }
    }

    // MARK: Init

    init() {
        let config = NavigationConfiguration(
            restorationKey: nil,
            verbosity: .info
        )
        rootNavigator = NavigatorUI.Navigator(configuration: config)
    }
}

// MARK: - NavigatorPublic

extension DefaultNavigator: NavigatorPublic {
    var rootView: AnyView {
        AnyView(RootView(navigator: rootNavigator))
    }
}

// MARK: - Navigator

extension DefaultNavigator: Navigator {
    func navigate(to destination: AppNavigationDestination, method: NavigationMethod) {
        currentNavigator.navigate(to: destination, method: method.asNavigatorUINavigationMethod)
    }
    
    func dismiss() {
        currentNavigator.dismiss()
    }
    
    func pop() {
        currentNavigator.pop()
    }

    func changeTab(to tab: MainTab, values: [any Hashable]?) {
        let values: [any Hashable] = [tab] + (values ?? [])
        rootNavigator.send(values: values)
    }
}
