//
//  Resolver+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

import Common

import Data
import UI

extension Resolver {
    static func registerDependencies() {
        registerDataServices()
        registerUI()
    }
}
