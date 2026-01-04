//
//  LoadingAggregatedEvent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 01..
//

import Foundation

public protocol LoadingAggregatedEvent: Hashable, Equatable {
    var numberOfItems: Int { get }
    var progressValue: Double { get }
    var isFinished: Bool { get }
}
