//
//  AudioInfo.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

public struct AudioInfo: Equatable {
    public let id: String
    public let duration: Int

    public init(id: String, duration: Int) {
        self.id = id
        self.duration = duration
    }

    public static func == (_ lhs: AudioInfo, _ rhs: AudioInfo) -> Bool {
        lhs.id == rhs.id && lhs.duration == rhs.duration
    }
}
