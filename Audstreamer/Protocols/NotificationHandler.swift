//
//  NotificationHandler.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 03..
//

import UIKit
import Combine

protocol NotificationHandler {
    func setupNotifications()
    func handleDeviceToken(_ token: Data)
    func handleFetchNotification(completion: @escaping (UIBackgroundFetchResult) -> Void)
    func getEpisodeID() -> AnyPublisher<String?, Error>
    func resetEpisodeID() -> AnyPublisher<Void, Error>
}
