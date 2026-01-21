//
//  UI+DI.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Common

extension Resolver {
    @MainActor
    public static func registerUI() {
        registerNavigator()
        registerFilterHelper()
    }
}

extension Resolver {
    @MainActor
    private static func registerNavigator() {
        register { DefaultNavigator() }
            .implements(NavigatorPublic.self)
            .implements(Navigator.self)
            .scope(.cached)
    }

    @MainActor
    private static func registerFilterHelper() {
        register { FilterHelper() }
            .scope(.unique)
    }
}
