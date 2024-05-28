//
//  UserDefaults+Extensions.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 01..
//

import Foundation

extension UserDefaults {
    @objc var episodesData: Data? {
        get { data(forKey: "EpisodesJSON") }
        set { set(newValue, forKey: "EpisodesJSON") }
    }
}
