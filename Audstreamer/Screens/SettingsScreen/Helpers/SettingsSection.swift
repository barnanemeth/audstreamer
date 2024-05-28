//
//  SettingsSection.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import Foundation

struct SettingsSection: Hashable, Equatable {

    // MARK: Properties

    let title: String?
    let items: [SettingsItem]
}
