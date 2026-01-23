//
//  App.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2026. 01. 03..
//

import SwiftUI

import Common
import UI

@main
struct App: SwiftUI.App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                Resolver.resolve(NavigatorPublic.self).rootView
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background else { return }
            appDelegate.synchronizeCloud()
        }
    }
}
