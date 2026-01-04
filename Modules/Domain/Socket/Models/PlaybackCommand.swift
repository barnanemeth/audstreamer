//
//  PlaybackCommand.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 27..
//

import Foundation

public enum PlaybackCommand {

    // MARK: Cases

    case play
    case pause
    case skipForward
    case skipBackward
    case seek(Double)

    // MARK: Properties

    public var data: [Any] {
        switch self {
        case .play: return ["play"]
        case .pause: return ["pause"]
        case .skipForward: return ["skipForward"]
        case .skipBackward: return ["skipBackward"]
        case let .seek(percent): return ["seek", percent]
        }
    }

    // MARK: Init

    // swiftlint:disable:next cyclomatic_complexity
    public init?(data: [Any]?) {
        guard let array = data?.first as? NSArray,
              let type = array.firstObject as? String else { return nil }
        switch type {
        case "play": self = .play
        case "pause": self = .pause
        case "skipForward": self = .skipForward
        case "skipBackward": self = .skipBackward
        case "seek":
            guard let percent = array.lastObject as? Double else { return nil }
            self = .seek(percent)
        default: return nil
        }
    }
}
