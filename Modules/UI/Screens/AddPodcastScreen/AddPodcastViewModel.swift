//
//  NewPodcastViewModel.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import Foundation

import Common
import Domain
import UIComponentKit

@Observable
final class AddPodcastViewModel {

    // MARK: Dependencies

    @ObservationIgnored @Injected private var podcastService: PodcastService
    @ObservationIgnored @Injected private var navigator: Navigator

    // MARK: Properties

    var feedURL = ""
    private(set) var isLoading = false
    let urlValidationRule = URLValidationRule(errorMessage: "Invalid URL")
    var addPodcastResult: ValidationResult = .valid
    var currentlyShowingDialog: DialogDescriptor?
}

// MARK: - View model

extension AddPodcastViewModel: ViewModel {
    func subscribe() async { }
}

// MARK: - Events

extension AddPodcastViewModel {
    @MainActor
    func addPodcast() async {
        guard let url = URL(string: feedURL) else { return }
        do {
            try await podcastService.addPodcastFeed(url).value
            navigator.dismiss()
        } catch let podcastServiceError as PodcastServiceError where podcastServiceError == .alreadyExists {
            addPodcastResult = .invalid(message: "You have already subscribed to this podcast")
        } catch {
            currentlyShowingDialog = DialogDescriptor(title: L10n.error, message: error.localizedDescription)
        }
    }

    @MainActor
    func dismiss() {
        navigator.dismiss()
    }
}
