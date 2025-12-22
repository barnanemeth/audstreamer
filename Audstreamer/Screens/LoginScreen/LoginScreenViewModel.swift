//
//  LoginScreenViewModel.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import UIKit
import Combine
import UserNotifications

enum LoginScreenParam: NavigationParameterizable {
    case shouldShowPlayerAtDismiss(Bool)
}

final class LoginScreenViewModel: ScreenViewModelWithParam {

    // MARK: Dependencies

    @Injected private var authorization: Authorization
    @Injected private var secureStore: SecureStore
    @Injected private var networking: Networking
    @Injected private var account: Account
    @Injected private var socket: Socket
    @Injected private var navigator: Navigator

    // MARK: Properties

    @Published private(set) var isLoading = false

    // MARK: Private properties

    private var shouldShowPlayerAtDismiss = false
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - ScreenViewModelWithParam

extension LoginScreenViewModel {
    func setParameter(_ parameter: LoginScreenParam) {
        guard case let .shouldShowPlayerAtDismiss(shouldShowPlayer) = parameter else { return }
        shouldShowPlayerAtDismiss = shouldShowPlayer
    }
}

// MARK: - Actions

extension LoginScreenViewModel {
    func authorize() {
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
                    default: navigator.presentAlert(for: authorizationError)
                    }
                case let .failure(error):
                    try? secureStore.deleteToken()
                    navigator.presentAlert(for: error)
                case .finished:
                    finishedOrCancelled()
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    func finishedOrCancelled() {
        if shouldShowPlayerAtDismiss {
            let playerScreen: PlayerScreen = Resolver.resolve()
            let navigationController = UINavigationController(rootViewController: playerScreen) // Note: with SwiftUI this is not necessary
            navigationController.modalPresentationStyle = .overCurrentContext
            navigationController.definesPresentationContext = true

            navigator.dismissAndPresent(navigationController)
        } else {
            navigator.dismiss()
        }
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
