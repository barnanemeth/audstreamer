//
//  AppDelegate.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 07..
//

import Foundation
import UIKit
import Combine
import SwiftUI

import Common
import Domain
import UI

final class AppDelegate: UIResponder {

    // MARK: Dependencies

    @LazyInjected private var notificationHandler: NotificationHandler
    @LazyInjected private var shortcutHandler: ShortcutHandler

    // MARK: Properties

    var window: UIWindow?

    // MARK: Private properties

    private let applicationLoader = ApplicationLoader()
}

// MARK: - UIApplicationDelegate methods

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
        applicationLoader.load()
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = .zero
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        applicationLoader.synchronizePrivateCloud()
        applicationLoader.synchronizePublicCloud()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        applicationLoader.synchronizePrivateCloud()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        notificationHandler.handleDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        notificationHandler.handleFetchNotification(completion: completionHandler)
    }

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        shortcutHandler.handleShortcutItemAction(shortcutItem, completion: completionHandler)
    }
}
