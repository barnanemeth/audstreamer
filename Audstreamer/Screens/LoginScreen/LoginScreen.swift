//
//  LoginScreen.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 16..
//

import SwiftUI

final class LoginScreen: UIHostingController<LoginView> {
    init(viewModel: LoginViewModel) {
        super.init(rootView: LoginView(viewModel: viewModel))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
