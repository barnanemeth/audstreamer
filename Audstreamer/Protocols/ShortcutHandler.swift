//
//  ShortcutHandler.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 12. 09..
//

import UIKit
import Combine

protocol ShortcutHandler {
    func setupItems()
    func getEpisodeID() -> AnyPublisher<String?, Error>
    func handleShortcutItemAction(_ shortcutItem: UIApplicationShortcutItem, completion: @escaping ((Bool) -> Void))
}
