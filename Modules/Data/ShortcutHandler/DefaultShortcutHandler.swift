//
//  DefaultShortcutHandler.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 12. 09..
//

import UIKit
import Combine

import Common
import Domain

final class DefaultShortcutHandler {

    // MARK: Constants

    private enum Constant {
        static let episodeIDUserInfoKey = "episodeID"
    }

    private enum ShortcutItemType: String {
        case lastPlayedEpisode
        case newestEpisode
    }

    // MARK: Dependencies

    @LazyInjected private var episodeService: EpisodeService

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private let episodeIDSubject = CurrentValueSubject<String?, Error>(nil)
}

// MARK: - ShortcutHandler

extension DefaultShortcutHandler: ShortcutHandler {
    func setupItems() {
        let lastPlayedEpisode = episodeService.lastPlayedEpisode()
        let newestEpisode = episodeService.episodes(matching: nil)
            .map { $0.max(by: { $0.publishDate < $1.publishDate }) }

        Publishers.CombineLatest(lastPlayedEpisode, newestEpisode)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [unowned self] lastPlayedEpisode, newestEpisode in
                var items = [UIApplicationShortcutItem]()

                if let lastPlayedEpisode = lastPlayedEpisode {
                    items.append(self.shortcutItem(for: lastPlayedEpisode, type: .lastPlayedEpisode))
                }

                if let newestEpisode = newestEpisode, newestEpisode.id != lastPlayedEpisode?.id {
                    items.append(self.shortcutItem(for: newestEpisode, type: .newestEpisode))
                }

                UIApplication.shared.shortcutItems = items
            })
            .store(in: &cancellables)
    }

    func getEpisodeID() -> AnyPublisher<String?, Error> {
        episodeIDSubject.eraseToAnyPublisher()
    }

    func handleShortcutItemAction(_ shortcutItem: UIApplicationShortcutItem, completion: @escaping ((Bool) -> Void)) {
        episodeIDSubject.send(getEpisodeID(from: shortcutItem))
        completion(true)
    }
}

// MARK: - Helpers

extension DefaultShortcutHandler {
    private func shortcutItem(for episode: Episode, type: ShortcutItemType) -> UIApplicationShortcutItem {
        let title: String
        switch type {
        case .lastPlayedEpisode: title = L10n.playLastPlayedEpisode
        case .newestEpisode: title = L10n.playNewestEpisode
        }

        return UIApplicationShortcutItem(
            type: type.rawValue,
            localizedTitle: title,
            localizedSubtitle: episode.title,
            icon: UIApplicationShortcutIcon(systemImageName: "play.circle.fill"),
            userInfo: [Constant.episodeIDUserInfoKey: NSString(string: episode.id)]
        )
    }

    private func getEpisodeID(from item: UIApplicationShortcutItem) -> String? {
        let userInfo = item.userInfo
        guard let episodeID = userInfo?[Constant.episodeIDUserInfoKey] as? String else { return nil }
        return episodeID
    }
}
