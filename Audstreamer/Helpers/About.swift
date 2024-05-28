//
//  About.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 17..
//

import Foundation

enum About {

    // MARK: Properties

    static var versionString: String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

        return L10n.version(appVersion, buildNumber)
    }

    static var copyrightString: String {
        let yearString = Calendar.current.component(.year, from: Date()).description
        return L10n.copyright(yearString, L10n.authorName)
    }
}
