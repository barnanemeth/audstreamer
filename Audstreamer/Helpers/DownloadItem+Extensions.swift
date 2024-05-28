//
//  DownloadItem+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2023. 06. 23..
//

import Foundation

extension Downloadable {
    var isSilentDownloading: Bool {
        guard let isSilentDownloading = userInfo?[UserInfoKeys.isSilentDownloading] as? Bool else { return false }
        return isSilentDownloading
    }
}
