//
//  Calendar.Component+Extensions.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 19..
//

import Foundation

extension Calendar.Component {
    var formatString: String {
        switch self {
        case .year: return "yyyy"
        case .month: return "MMMM"
        case .day: return "d"
        case .hour: return "HH"
        default: return ""
        }
    }
}

extension Sequence where Element == Calendar.Component {
    var dateFormat: String {
        var outstring = reduce(into: "", { out, component in
            out += "\(component.formatString) "
        })
        outstring.removeLast()
        return outstring
    }
}
