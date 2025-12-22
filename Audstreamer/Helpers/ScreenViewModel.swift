//
//  ScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 15..
//

import UIKit

// MARK: - View model

protocol ScreenViewModelable {}

protocol ScreenViewModelWithParam: ParameterReceivable, ScreenViewModelable {}

protocol ScreenViewModel: ScreenViewModelable {}

protocol NavigationParameterizable {}

protocol ParameterReceivable {
    associatedtype ParamType: NavigationParameterizable
    mutating func setParameter(_ parameter: ParamType)
}

// MARK: - Screen

protocol Screen where Self: UIViewController {
    associatedtype ViewModelType: ScreenViewModelable
    var viewModel: ViewModelType { get }
}

protocol ScreenConvertible {
    var vc: UIViewController { get }

    func setNavigationParameter(_ parameter: NavigationParameterizable)
}

extension ScreenConvertible where Self: UIViewController {
    var vc: UIViewController { self }
}
