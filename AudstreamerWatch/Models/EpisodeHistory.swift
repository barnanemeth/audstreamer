//
//  EpisodeHistory.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2023. 06. 03..
//

struct EpisodeHistory {

    // MARK: Properties

    let current: [EpisodeCommon]?
    let next: [EpisodeCommon]?

    // MARK: Init

    init() {
        current = nil
        next = nil
    }

    init(current: [EpisodeCommon]? = nil, next: [EpisodeCommon]? = nil) {
        self.current = current
        self.next = next
    }

    // MARK: Public methods

    func appending(_ episodes: [EpisodeCommon]) -> EpisodeHistory {
        if current == nil, next == nil {
            return EpisodeHistory(current: episodes)
        } else if next == nil {
            return EpisodeHistory(current: current, next: episodes)
        }
        return EpisodeHistory(current: next, next: episodes)
    }
}
