//
//  Previewable.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 12. 24..
//

import UIKit

protocol Previewable: UIView {
    var targetView: UITargetedPreview { get }
}
