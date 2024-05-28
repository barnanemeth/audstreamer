//
//  AppleIDAuthorization.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 17..
//

import Foundation
import Combine
import AuthenticationServices

final class AppleIDAuthorization: NSObject {

    // MARK: Private properties

    private var authorizationSubject = PassthroughSubject<Data, Error>()
}

// MARK: - Authorization

extension AppleIDAuthorization: Authorization {
    func authorize() -> AnyPublisher<Data, Error> {
        defer {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }

        authorizationSubject = PassthroughSubject<Data, Error>()
        return authorizationSubject.eraseToAnyPublisher()
    }

    func checkAuthorizationStatus(for userID: String) -> AnyPublisher<AuthorizationState, Error> {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        return Promise<AuthorizationState, Error> { promise in
            appleIDProvider.getCredentialState(forUserID: userID, completion: { credentialState, _  in
                switch credentialState {
                case .authorized: promise(.success(.authorized))
                case .revoked: promise(.success(.revoked))
                case .notFound: promise(.success(.notFound))
                case .transferred: promise(.success(.transferred))
                @unknown default: preconditionFailure("Unreacheable default")
                }
            })
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding methods

extension AppleIDAuthorization: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        Resolver.resolve() as UIWindow
    }
}

// MARK: - ASAuthorizationControllerDelegate methods

extension AppleIDAuthorization: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authorizationError = error as? ASAuthorizationError, case .canceled = authorizationError.code {
            authorizationSubject.send(completion: .failure(AuthorizationError.userCanceled))
        } else {
            authorizationSubject.send(completion: .failure(error))
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken else {
            return authorizationSubject.send(completion: .failure(AuthorizationError.missingCredential))
        }
        authorizationSubject.send(identityToken)
    }
}
