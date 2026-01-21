//
//  APIClientMiddleware.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 19..
//

import Foundation

@preconcurrency import Common

internal import HTTPTypes
internal import OpenAPIRuntime

struct APIClientMiddleware: ClientMiddleware {

    // MARK: Constants

    private enum Constant {
        static let apiKeyHeaderKey = HTTPField.Name("X-Api-Key")!
        static let authorizationHeaderKey: HTTPField.Name = .authorization
        static let authorizationHeaderValueFormat = "Bearer %@"
        static let onlyAPIKeyOperationIDs: Set<String> = [
            "createDevice"
        ]
    }

    // MARK: Dependencies

    @Injected private var secureStore: SecureStore

    func intercept(
        _ request: HTTPTypes.HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPTypes.HTTPRequest, HTTPBody?, URL) async throws -> (HTTPTypes.HTTPResponse, HTTPBody?)) async throws -> (HTTPTypes.HTTPResponse, HTTPBody?) {
            var headerFields = Set<HTTPField>()

            headerFields.insert(HTTPField(name: Constant.apiKeyHeaderKey, value: AppSettings.apiKey))

            if !Constant.onlyAPIKeyOperationIDs.contains(operationID), let accessToken {
                headerFields.insert(HTTPField(name: Constant.authorizationHeaderKey, value: String(format: Constant.authorizationHeaderValueFormat, accessToken)))
            }

            var request = request
            headerFields.forEach { request.headerFields.append($0) }

            let (response, body) = try await next(request, body, baseURL)
            handleResponseIfNeeded(response)
            return (response, body)
    }
}

// MARK: - ClientMiddleware

extension APIClientMiddleware {

}

// MARK: - Helpers

extension APIClientMiddleware {
    private var accessToken: String? {
        try? secureStore.getToken()
    }

    private func handleResponseIfNeeded(_ response: HTTPResponse) {
        guard response.status == .unauthorized else { return }
        NotificationCenter.default.post(Notification(name: .accessTokenDidExpired))
        try? secureStore.deleteToken()
    }
}
