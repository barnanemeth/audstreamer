//
//  EpisodesViewModel.swift
//  AudstreamerWatch Watch App
//
//  Created by Barna Nemeth on 2023. 05. 17..
//

import Foundation
import Combine

final class EpisodesViewModel: ObservableObject {

    // MARK: Dependencies

    @Injected private var episodeService: EpisodeService
    @Injected private var updater: Updater

    // MARK: Properties

    @Published private(set) var title = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    @Published private(set) var episodes = [EpisodeCommon]()

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private lazy var sharedEpisodes: AnyPublisher<[EpisodeCommon], Error> = {
        episodeService.getEpisodes().shareReplay()
    }()

    // MARK: Init

    init() {
        setupBindings()
        updater.startUpdating()
    }
}

// MARK: - Helpers

extension EpisodesViewModel {
    private func setupBindings() {
        sharedEpisodes
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$episodes)
    }
}
