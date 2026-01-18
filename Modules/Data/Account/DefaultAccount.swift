//
//  DefaultAccount.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 24..
//

import Foundation
import Combine
import UserNotifications
import UIKit

import Common
import Domain

final class DefaultAccount {

    // MARK: Constants

    private enum Constant {
        static let notificationTokenUserDefaultsKey = "NotificationToken"
    }

    // MARK: Dependencies

    @Injected private var secureStore: SecureStore
    @Injected private var apiClient: APIClient
    @Injected private var authorization: Authorization
    @Injected private var socket: Socket

    // MARK: Private properties

    private let userDefaults = UserDefaults.standard
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

    func login() -> AnyPublisher<Void, Error> {
        authorization.authorize()
            .tryMap { [unowned self] in try secureStore.storeToken($0) }
            .flatMap { [unowned self] in refresh() }
            .flatMap { [unowned self] in connectSocketIfNeeded() }
            .flatMap { [unowned self] in requestNotificationPermission() }
            .flatMap { [unowned self] in registerDeviceIfPossible() }
            .catch { [unowned self] error in
                switch error {
                case let authorizationError as AuthorizationError where authorizationError == .userCanceled:
                    break
                default:
                    try? secureStore.deleteToken()
                }
                return Fail<Void, Error>(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func logout() -> AnyPublisher<Void, Error> {
        apiClient.deleteDevice()
            .flatMap { [unowned self] in socket.disconnect() }
            .tryMap { [unowned self] in try secureStore.deleteToken() }
            .flatMap { [unowned self] in refresh() }
            .eraseToAnyPublisher()
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

    private func connectSocketIfNeeded() -> AnyPublisher<Void, Never> {
        socket.getStatus()
            .replaceError(with: .disconnected)
            .first()
            .flatMap { [unowned self] status in
                switch status {
                case .disconnected, .pending: socket.connect().replaceError(with: ()).eraseToAnyPublisher()
                case .connected: Just(()).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    private func requestNotificationPermission() -> AnyPublisher<Void, Error> {
        Promise { promise in
            let userNotificationCenter = UNUserNotificationCenter.current()
            userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                if let error {
                    return promise(.failure(error))
                }
                return promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }

    private func registerDeviceIfPossible() -> AnyPublisher<Void, Error> {
        Promise { promise in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                let token = self.userDefaults.string(forKey: Constant.notificationTokenUserDefaultsKey)
                promise(.success(token))
            }
        }
        .flatMap { [unowned self] token in
            guard let token else { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
            return apiClient.addDevice(with: token)
        }
        .subscribe(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
