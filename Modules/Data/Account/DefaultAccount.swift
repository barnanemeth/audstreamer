//
//  DefaultAccount.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 24..
//

import Foundation
import Combine

import Common
import Domain

final class DefaultAccount {

    // MARK: Dependencies

    @Injected private var secureStore: SecureStore

    // MARK: Private properties

    private let isLoggedInSubject = CurrentValueSubject<Bool, Error>(false)

    // MARK: Init

    init() {
        refreshSubject()
    }
}

// MARK: - Account

extension DefaultAccount: Account {
    func isLoggedIn() -> AnyPublisher<Bool, Error> {
        isLoggedInSubject.eraseToAnyPublisher()
    }

    func logout() -> AnyPublisher<Void, Error> {
        do {
            try secureStore.deleteToken()
            return Just.void()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func refresh() -> AnyPublisher<Void, Error> {
        Just(refreshSubject()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultAccount {
    private func refreshSubject() {
        isLoggedInSubject.send((try? secureStore.getToken()) != nil)
    }
}
