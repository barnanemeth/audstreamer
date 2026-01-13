//
//  DefaultNotificationHandler.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 03..
//

import UIKit
import Combine
import UserNotifications
import UniformTypeIdentifiers

import Common
import Domain

final class DefaultNotificationHandler: NSObject {

    // MARK: Constants

    private enum Constant {
        static let notificationTokenUserDefaultsKey = "NotificationToken"
        static let episodeIDKey = "episodeID"
    }

    // MARK: Dependencies

    @LazyInjected private var secureStore: SecureStore
    @LazyInjected private var apiClient: APIClient
    @LazyInjected private var database: Database

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private let episodeIDSubject = CurrentValueSubject<String?, Error>(nil)
    private var hasUserToken: Bool {
        (try? self.secureStore.getToken()) != nil
    }
}

// MARK: - NotificationHandler

extension DefaultNotificationHandler: NotificationHandler {
    func setupNotifications() {
        guard hasUserToken else { return }
        let userNotificationCenter = UNUserNotificationCenter.current()
        userNotificationCenter.delegate = self
        userNotificationCenter.requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { isGranted, _ in
                guard isGranted else { return }
                DispatchQueue.main.async(execute: {
                    UIApplication.shared.registerForRemoteNotifications()
                })
            }
        )
    }

    func handleDeviceToken(_ token: Data) {
        let hexString = token.hexString
        let userDefaults = UserDefaults.standard
        userDefaults.set(hexString, forKey: Constant.notificationTokenUserDefaultsKey)
        apiClient.addDevice(with: hexString).sink().store(in: &cancellables)
    }

    func handleFetchNotification(completion: @escaping (UIBackgroundFetchResult) -> Void) {
        database.getLastEpisodePublishDate()
            .first()
            .flatMap { [unowned self] in self.apiClient.getEpisodes(from: $0) }
            .flatMap { [unowned self] episodes -> AnyPublisher<[Episode], Error> in
                let episodesPublisher = Just(episodes).setFailureType(to: Error.self)
                let insert = self.database.insertEpisodes(episodes)

                return Publishers.Zip(episodesPublisher, insert).map { $0.0 }.eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { subscriptionCompletion in
                guard case .failure = subscriptionCompletion else { return }
                completion(.failed)
            }, receiveValue: { [unowned self] episodes in
                if episodes.isEmpty {
                    completion(.noData)
                } else {
                    self.postNotifications(for: episodes)
                    self.setBadge(to: episodes.count)
                    completion(.newData)
                }
            })
            .store(in: &cancellables)
    }

    func getEpisodeID() -> AnyPublisher<String?, Error> {
        episodeIDSubject.eraseToAnyPublisher()
    }

    func resetEpisodeID() -> AnyPublisher<Void, Error> {
        Just(episodeIDSubject.send(nil)).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultNotificationHandler {
    private func setBadge(to badgeNumber: Int) {
        UIApplication.shared.applicationIconBadgeNumber = badgeNumber
    }

    private func getEpisodeID(from notificationResponse: UNNotificationResponse) -> String? {
        let userInfo = notificationResponse.notification.request.content.userInfo
        guard let episodeID = userInfo[Constant.episodeIDKey] as? String else { return nil }
        return episodeID
    }

    private func postNotifications(for episodes: [Episode]) {
        guard !episodes.isEmpty else { return }
        let title: String
        let body: String
        let attachments: [UNNotificationAttachment]
        let userInfo: [AnyHashable: Any]

        if episodes.count > 1 {
            title = L10n.newEpisode
            body = L10n.newEpisodesAreAvailable
            attachments = []
            userInfo = [:]
        } else {
            guard let firstEpisode = episodes.first else { return }
            title = L10n.newEpisode
            body = firstEpisode.title
            userInfo = [Constant.episodeIDKey: firstEpisode.id]
            attachments = getAttachments(for: firstEpisode)
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.attachments = attachments
        content.userInfo = userInfo
        content.badge = (episodes.count) as NSNumber
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func getAttachments(for episode: Episode) -> [UNNotificationAttachment] {
        // TODO: percent encoding?
        guard let imageURL = episode.image,
              let data = try? Data(contentsOf: imageURL),
              let tempDirectoryURL = URL(string: "file://\(NSTemporaryDirectory())") else { return [] }

        let filename = "\(UUID().uuidString).jpg"
        let path = tempDirectoryURL.appendingPathComponent(filename)
        do {
            try data.write(to: path)
            let attachment = try UNNotificationAttachment(
                identifier: UUID().uuidString,
                url: path,
                options: [UNNotificationAttachmentOptionsTypeHintKey: UTType.jpeg]
            )
            return [attachment]
        } catch {
            return []
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate methods

extension DefaultNotificationHandler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        setBadge(to: .zero)
        episodeIDSubject.send(getEpisodeID(from: response))
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.banner])
    }
}
