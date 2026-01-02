//
//  Double+ToHoursMinutesSeconds.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 09..
//

import Foundation

// MARK: - Typealiases

extension Double {
    private typealias IntervalCombination = (hours: Int, minutes: Int, seconds: Int)
}

// MARK: - Public methods

extension Double {
    var secondsToHoursMinutesSecondsString: String {
        let time = secondsToHoursMinutesSeconds
        let hoursString = time.hours.description.count == 2 ? time.hours.description : "0\(time.hours.description)"
        let minutesString = time.minutes.description.count == 2 ?
            time.minutes.description :
            "0\(time.minutes.description)"
        let secondsString = time.seconds.description.count == 2 ?
            time.seconds.description :
            "0\(time.seconds.description)"
        return "\(hoursString):\(minutesString):\(secondsString)"
    }
}

// MARK: - Helpers

extension Double {
    private var secondsToHoursMinutesSeconds: IntervalCombination {
        guard isNormal else { return (.zero, .zero, .zero) }
        return (Int(self) / 3600, (Int(self) % 3600) / 60, (Int(self) % 3600) % 60)
    }
}
