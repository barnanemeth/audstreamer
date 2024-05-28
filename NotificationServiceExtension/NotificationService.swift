//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Barna Nemeth on 2023. 04. 06..
//

import UserNotifications
import UniformTypeIdentifiers

final class NotificationService: UNNotificationServiceExtension {

    // MARK: Constants

    private enum Constant {
        static let apsKey = "aps"
        static let episodeIDKey = "episodeID"
        static let imageURLKey = "imageURL"
    }

    // MARK: Properties

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    // MARK: Public methods

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            bestAttemptContent.title = NSLocalizedString("newEpisode", comment: "New episode")
            bestAttemptContent.userInfo = buildUserInfo(from: request.content)
            bestAttemptContent.attachments = getAttachments(for: request.content)

            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

// MARK: - Helpers

extension NotificationService {
    private func buildUserInfo(from notificationContent: UNNotificationContent) -> [AnyHashable: Any] {
        guard let episodeID = notificationContent.userInfo[Constant.episodeIDKey] as? String else { return [:] }
        return [Constant.episodeIDKey: episodeID]
    }

    private func getImageURL(from notificationContent: UNNotificationContent) -> URL? {
        guard let imageURLString = notificationContent.userInfo[Constant.imageURLKey] as? String,
              let encodedString = imageURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: encodedString)
    }

    private func getAttachments(for notificationContent: UNNotificationContent) -> [UNNotificationAttachment] {
        guard let imageURL = getImageURL(from: notificationContent),
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
