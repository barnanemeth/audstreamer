//
//  ShortcutHandler.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 12. 09..
//

import UIKit
import Combine

public protocol ShortcutHandler {
    func setupItems()
    func getEpisodeID() -> AnyPublisher<String?, Error>
    #if !os(watchOS)
    func handleShortcutItemAction(_ shortcutItem: UIApplicationShortcutItem, completion: @escaping ((Bool) -> Void))
    #endif
}
