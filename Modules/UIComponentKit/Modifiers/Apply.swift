//
//  Apply.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import SwiftUI

extension View {
    public func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
