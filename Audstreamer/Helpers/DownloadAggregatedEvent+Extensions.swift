//
//  DownloadAggregatedEvent+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 23..
//

import Foundation

extension DownloadAggregatedEvent {
    var isSilentDownloading: Bool {
        guard let isSilentDownloading = userInfo?[UserInfoKeys.isSilentDownloading] as? Bool else { return false }
        return isSilentDownloading
    }
}
