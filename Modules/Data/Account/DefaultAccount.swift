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

internal import AudstreamerAPIClient

enum DefaultAccountError: Error {
    case cannotCreateDevice
    case cannotUpdateDevice
    case cannotDeleteDevice
}

final class DefaultAccount {

    // MARK: Constants

    private enum Constant {
        static let notificationTokenUserDefaultsKey = "NotificationToken"
    }

    // MARK: Dependencies

    @Injected private var secureStore: SecureStore
    @Injected private var client: Client
    @Injected private var authorization: Authorization
    @Injected private var socket: Socket

    // MARK: Private properties

    private let userDefaults = UserDefaults.standard
    private let isLoggedInSubject = CurrentValueSubject<Bool, Error>(false)
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init() {
        refreshSubject()
        subscribeToAccessTokenDidExpired()
    }
}

// MARK: - Account

extension DefaultAccount: Account {
    func isLoggedIn() -> AnyPublisher<Bool, Error> {
        isLoggedInSubject.eraseToAnyPublisher()
    }

    func login() -> AnyPublisher<Void, Error> {
        authorization.authorize()
            .flatMap { [unowned self] in login(with: $0) }
            .tryMap { [unowned self] in try secureStore.storeToken($0) }
            .map { [unowned self] in isLoggedInSubject.send(true) }
            .flatMap { [unowned self] in connectSocketIfNeeded() }
            .flatMap { [unowned self] in requestNotificationPermission() }
            .flatMap { [unowned self] in updateDeviceIfPossible() }
            .catch { [unowned self] error in
                switch error {
                case let authorizationError as AuthorizationError where authorizationError == .userCanceled:
                    break
                default:
                    try? secureStore.deleteToken()
                    isLoggedInSubject.send(false)
                }
                return Fail<Void, Error>(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func logout() -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher<Operations.logout.Output, Error> {
            try await self.client.logout()
        }
        .tryMap { response in
            switch response {
            case .ok: return
            default: throw DefaultAccountError.cannotDeleteDevice
            }
        }
        .replaceError(with: ())
        .flatMap { [unowned self] in socket.disconnect() }
        .map { [unowned self] in try? secureStore.deleteToken() }
        .map { [unowned self] in isLoggedInSubject.send(false) }
        .eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Void, Error> {
        ThrowingAsyncPublisher {
            try await self.client.checkAuthentication()
        }
        .map { [unowned self] response in
            let isLoggedIn = switch response {
            case .ok: true
            default: false
            }
            isLoggedInSubject.send(isLoggedIn)
        }
        .eraseToAnyPublisher()
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

    private func updateDeviceIfPossible() -> AnyPublisher<Void, Error> {
        Promise { promise in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                let token = self.userDefaults.string(forKey: Constant.notificationTokenUserDefaultsKey)
                promise(.success(token))
            }
        }
        .flatMap { [unowned self] token -> AnyPublisher<Operations.updateNotificationToken.Output, Error> in
            guard let token else { return Empty<Operations.updateNotificationToken.Output, Error>(completeImmediately: true).eraseToAnyPublisher() }
            return ThrowingAsyncPublisher<Operations.updateNotificationToken.Output, Error> {
                try await self.client.updateNotificationToken(.init(body: .json(.init(token: token))))
            }
            .eraseToAnyPublisher()
        }
        .tryMap { response in
            switch response {
            case .ok: return
            default: throw DefaultAccountError.cannotUpdateDevice
            }
        }
        .replaceEmpty(with: ())
        .eraseToAnyPublisher()
    }

    private func subscribeToAccessTokenDidExpired() {
        NotificationCenter.default.publisher(for: Notification.Name.accessTokenDidExpired)
            .toVoid()
            .sink { [unowned self] in isLoggedInSubject.send(false) }
            .store(in: &cancellables)
    }

    private func login(with appleToken: String) -> AnyPublisher<String, Error> {
        ThrowingAsyncPublisher<Operations.loginWithApple.Output, Error> {
            let deviceID = await UIDevice.current.identifierForVendor ?? UUID()
            return try await self.client.loginWithApple(
                .init(body: .json(.init(token: appleToken, deviceID: deviceID.uuidString)))
            )
        }
        .tryMap { response in
            switch response {
            case let .ok(successfulResponse):
                return try successfulResponse.body.json.token
            default:
                throw DefaultAccountError.cannotCreateDevice
            }
        }
        .eraseToAnyPublisher()
    }
}
