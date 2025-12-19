//
//  AudstreamerWatchApp.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import SwiftUI
import WatchKit

@main
struct AudstreamerWatchApp: App {

    // MARK: Private properties

    @WKApplicationDelegateAdaptor var appDelegate: WatchAppDelegate

    // MARK: UI

    var body: some Scene {
        WindowGroup {
            EpisodesView()
        }
    }
}
