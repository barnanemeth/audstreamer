//
//  Account.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 24..
//

import Combine

protocol Account {
    func isLoggedIn() -> AnyPublisher<Bool, Error>
    func logout() -> AnyPublisher<Void, Error>
    func refresh() -> AnyPublisher<Void, Error>
}
