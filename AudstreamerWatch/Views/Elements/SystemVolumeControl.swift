//
//  SystemVolumeControl.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 19..
//

import SwiftUI
import WatchKit

struct SystemVolumeControl: WKInterfaceObjectRepresentable {
    typealias WKInterfaceObjectType = WKInterfaceVolumeControl

    /// `.local` controls watch playback, `.companion` controls paired iPhone.
    var origin: WKInterfaceVolumeControl.Origin = .local

    func makeWKInterfaceObject(context: Context) -> WKInterfaceVolumeControl {
        let control = WKInterfaceVolumeControl(origin: origin)
        control.focus() // send Digital Crown focus here
        return control
    }

    func updateWKInterfaceObject(_ control: WKInterfaceVolumeControl, context: Context) {
        // Keep focus (watchOS focus can move around as views update)
        control.focus()
    }
}
