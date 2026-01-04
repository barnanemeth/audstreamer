//
//  NavigationMethod.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2026. 01. 04..
//

internal import NavigatorUI

public enum NavigationMethod {
    case push
    case send
    case sheet
    case cover
    case managedSheet
    case managedCover

    var asNavigatorUINavigationMethod: NavigatorUI.NavigationMethod {
        switch self {
        case .push: .push
        case .send: .send
        case .sheet: .sheet
        case .cover: .cover
        case .managedSheet: .managedSheet
        case .managedCover: .managedCover
        }
    }
}
