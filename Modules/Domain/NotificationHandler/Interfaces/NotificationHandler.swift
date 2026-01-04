//
//  NotificationHandler.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 03..
//

import UIKit
import Combine

public protocol NotificationHandler {
    func setupNotifications()
    func handleDeviceToken(_ token: Data)
    #if !os(watchOS)
    func handleFetchNotification(completion: @escaping (UIBackgroundFetchResult) -> Void)
    #endif
    func getEpisodeID() -> AnyPublisher<String?, Error>
    func resetEpisodeID() -> AnyPublisher<Void, Error>
}
