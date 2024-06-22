//
//  LoadingScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation
import Combine

final class LoadingScreenViewModel: ScreenViewModel {
    
    // MARK: Constants
    
    private enum Constant {
        static let navigationDelay: DispatchQueue.SchedulerTimeType.Stride = 1
    }

    // MARK: Dependencies

    @Injected private var account: Account

    // MARK: Properties

    @Published var isLoading = false
    var navigateToPlayerScreenAction: CocoaAction?
    var navigateToLoginScreenAction: CocoaAction?
    var presentErrorAlertAction: Action<Error, Never>?

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Actions

extension LoadingScreenViewModel {
    func fetchData() {
        FetchUtil.fetchData()
            .delay(for: Constant.navigationDelay, scheduler: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [unowned self] _ in self.isLoading = true },
                          receiveCompletion: { [unowned self] _ in self.isLoading = false })
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished: self.navigateNext()
                case let.failure(error): self.presentErrorAlertAction?.execute(error)
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension LoadingScreenViewModel {
    private func navigateNext() {
        account.refresh()
            .flatMap { [unowned self] in self.account.isLoggedIn().first() }
            .map { [unowned self] in $0 ? self.navigateToPlayerScreenAction : self.navigateToLoginScreenAction }
            .sink { $0?.execute() }
            .store(in: &cancellables)
    }
}
