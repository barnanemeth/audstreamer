//
//  ScreenView.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI

protocol ScreenView: View {
    associatedtype ViewModelType: AnyObject

    var viewModel: ViewModelType { get }
    init(viewModel: ViewModelType)
}
