//
//  AppleIDAuthorization.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 17..
//

import Foundation
import Combine
import AuthenticationServices

import Common
import Domain

final class AppleIDAuthorization: NSObject {

    // MARK: Private properties

    private var authorizationSubject = PassthroughSubject<String, Error>()
}

// MARK: - Authorization

extension AppleIDAuthorization: Authorization {
    func authorize() -> AnyPublisher<String, Error> {
        defer {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }

        authorizationSubject = PassthroughSubject<String, Error>()
        return authorizationSubject.eraseToAnyPublisher()
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding methods

extension AppleIDAuthorization: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // swiftlint:disable force_unwrapping
        UIApplication.shared.connectedScenes.first { scene in
            scene.activationState == .foregroundActive
        }!.inputView!.window!
        // swiftlint:enable force_unwrapping
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
              let identityToken = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            return authorizationSubject.send(completion: .failure(AuthorizationError.missingCredential))
        }
        authorizationSubject.send(identityTokenString)
    }
}
