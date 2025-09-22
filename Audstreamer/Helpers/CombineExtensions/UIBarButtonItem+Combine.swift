//
//  UIBarButtonItem+Combine.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 09. 11..
//

import Combine
import UIKit

extension UIBarButtonItem {
    /// A publisher which emits whenever this UIBarButtonItem is tapped.
    var tapPublisher: AnyPublisher<Void, Never> {
        Publishers.ControlTarget(control: self,
                                 addTargetAction: { control, target, action in
                                    control.target = target
                                    control.action = action
                                 },
                                 removeTargetAction: { control, _, _ in
                                    control?.target = nil
                                    control?.action = nil
                                 })
                  .eraseToAnyPublisher()
  }
}
