//
//  Updater+DI.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Common
import Domain

extension Resolver {
    static func registerUpdaters() {
        register { DefaultPlayingUpdater() }
            .implements(PlayingUpdater.self)
            .scope(.cached)

        register { DefaultSocketUpdater() }
            .implements(SocketUpdater.self)
            .scope(.cached)

        register { DefaultDatabaseUpdater() }
            .implements(DatabaseUpdater.self)
            .scope(.cached)
    }
}
