//
//  BaseHostingScreen.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI

class BaseHostingScreen<Screen: ScreenView>: UIHostingController<Screen> {
    init() {
        super.init(rootView: Screen())
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
