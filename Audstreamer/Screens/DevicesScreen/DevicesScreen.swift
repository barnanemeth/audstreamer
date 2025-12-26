//
//  DevicesScreen.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 03. 09..
//

import UIKit
import Combine

final class DevicesScreen: BaseHostingScreen<DevicesView> {

    // MARK: Constants

    private enum Constant {
        static let height: CGFloat = 240
    }
}

// MARK: - Lifecycle

extension DevicesScreen {
    override func viewDidLoad() {
        super.viewDidLoad()

        var size = super.preferredContentSize
        size.height = Constant.height

        preferredContentSize = size
    }
}
