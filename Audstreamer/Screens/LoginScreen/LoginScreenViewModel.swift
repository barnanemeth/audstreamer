//
//  LoginScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import UIKit
import Combine
import UserNotifications

final class LoginScreenViewModel: ScreenViewModel {

    // MARK: Dependencies

    @Injected private var authorization: Authorization
    @Injected private var secureStore: SecureStore
    @Injected private var networking: Networking
    @Injected private var account: Account
    @Injected private var socket: Socket

    // MARK: Properties

    @Published var isLoading = false
    lazy var authorizeAction = CocoaAction(LoginScreenViewModel.authorize, in: self)
    var dismissAction: CocoaAction?
    var showErrorlAlertAction: Action<Error, Never>?

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Actions

extension LoginScreenViewModel {
    private func authorize() {
        authorization.authorize()
            .first()
            .tryMap { [unowned self] in try self.secureStore.storeToken($0) }
            .flatMap { [unowned self] in self.account.refresh() }
            .flatMap { [unowned self] in self.connectSocketIfNeeded() }
            .flatMap { [unowned self] in self.requestNotificationPermission().receive(on: DispatchQueue.main) }
            .flatMap { [unowned self] _ -> AnyPublisher<Void, Error> in
                UIApplication.shared.registerForRemoteNotifications()
                guard let notificationToken = UserDefaults.standard.string(forKey: "NotificationToken") else {
                    return Just.void()
                }
                return self.networking.addDevice(with: notificationToken)
                    .handleEvents(receiveSubscription: { _ in self.isLoading = true })
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveCompletion: { [unowned self] _ in self.isLoading = false })
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case let .failure(authorizationError as AuthorizationError):
                    switch authorizationError {
                    case .userCanceled: return
                    default: self.showErrorlAlertAction?.execute(authorizationError)
                    }
                case let .failure(error):
                    try? self.secureStore.deleteToken()
                    self.showErrorlAlertAction?.execute(error)
                case .finished:
                    self.dismissAction?.execute()
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension LoginScreenViewModel {
    private func requestNotificationPermission() -> AnyPublisher<Bool, Error> {
        let userNotificationCenter = UNUserNotificationCenter.current()
        return Promise<Bool, Error> { promise in
            userNotificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge],
                completionHandler: { isGranted, error in
                    if let error = error {
                        return promise(.failure(error))
                    }
                    promise(.success(isGranted))
                }
            )
        }
        .eraseToAnyPublisher()
    }

    private func connectSocketIfNeeded() -> AnyPublisher<Void, Error> {
        socket.getStatus()
            .first()
            .map { $0 == .connected }
            .flatMap { [unowned self] isConnected -> AnyPublisher<Void, Error> in
                guard !isConnected else { return Just.void() }
                return self.socket.connect()
            }
            .catch { _ in Just.void() }
            .eraseToAnyPublisher()
    }
}
