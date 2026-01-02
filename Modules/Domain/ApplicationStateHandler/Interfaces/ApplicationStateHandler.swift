//
//  ApplicationStateHandler.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 03..
//

import UIKit
import Combine

public protocol ApplicationStateHandler {
    func start()
    func stop()
    func getState() -> AnyPublisher<UIApplication.State, Error>
}
