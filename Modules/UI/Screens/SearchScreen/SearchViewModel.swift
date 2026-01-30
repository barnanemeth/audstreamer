//
//  SearchViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 21..
//

import Foundation
import Combine

import Common
import Domain

@Observable
final class SearchViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var podcastService: PodcastService
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    private(set) var searchKeyword: String?
    private(set) var podcasts: [Podcast]?

    // MARK: Private properties

    @ObservationIgnored private let searchKeywordSubject = CurrentValueSubject<String?, Never>(nil)
}

// MARK: - View model

extension SearchViewModel: ViewModel {
    func subscribe() async {
        await subscribeToPodcasts()
    }
}

// MARK: - Events

extension SearchViewModel {
    func changeSearchKeyword(_ searchKeyword: String?) {
        self.searchKeyword = searchKeyword
        searchKeywordSubject.send(searchKeyword)
    }

    @MainActor
    func toggleSubscription(for podcast: Podcast) async {
        do {
            if podcast.isSubscribed {
                try await podcastService.unsubscribe(from: podcast).value
            } else {
                try await podcastService.subscribe(to: podcast).value
            }
        } catch {
            print(error)
        }
    }

    @MainActor
    func navigateToPodcastDetails(for podcast: Podcast) {
        navigator.navigate(to: .podcastDetails(podcast: podcast, namespace: nil), method: .push)
    }
}

// MARK: - Helpers

extension SearchViewModel {
    @MainActor
    func subscribeToPodcasts() async {
        let searchResult = searchKeywordSubject
            .throttle(for: 1, scheduler: DispatchQueue.main, latest: true)
            .setFailureType(to: Error.self)
            .flatMapLatest { [unowned self] searchKeyword in
                if let searchKeyword {
                    podcastService.search(with: searchKeyword)
                } else {
                    podcastService.getTrending(maximumResult: nil)
                }
            }
        let savedPodcasts = podcastService.savedPodcasts(sortingPreference: nil)
        let publisher = Publishers.CombineLatest(searchResult, savedPodcasts)
            .map { searchResult, savedPodcasts in
                searchResult.map { podcast in
                    var podcast = podcast
                    podcast.isSubscribed = savedPodcasts.contains(where: { $0.id == podcast.id })
                    return podcast
                }
            }

        do {
            for try await podcasts in publisher.bufferedValues {
                self.podcasts = podcasts
            }
        } catch {
            print(error)
        }
    }
}
