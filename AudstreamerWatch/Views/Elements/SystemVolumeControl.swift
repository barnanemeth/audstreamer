//
//  SystemVolumeControl.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 19..
//

import SwiftUI
import WatchKit

struct SystemVolumeControl: WKInterfaceObjectRepresentable {
    var origin: WKInterfaceVolumeControl.Origin = .local

    func makeWKInterfaceObject(context: Context) -> WKInterfaceVolumeControl {
        let control = WKInterfaceVolumeControl(origin: origin)
        control.focus()
        return control
    }

    func updateWKInterfaceObject(_ control: WKInterfaceVolumeControl, context: Context) {
        control.focus()
    }
}
