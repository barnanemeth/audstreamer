//
//  DefaultAPIClient.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 15..
//

import UIKit

import Combine

final class DefaultAPIClient {

    // MARK: Inner types

    private enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }

    // MARK: Constants

    private enum Constant {
        static let apiKey = "66d9b38b-2736-4035-b6c5-643ffb30615a"
        static let defaultQueue = DispatchQueue.main
        static let noContentHTTPStatus = 204
        static let emptyBodyString = "[]"
    }

    // MARK: Dependencies

    @Injected private var secureStore: SecureStore

    // MARK: Private properties

    private let session = URLSession.shared
    private lazy var baseURL: URL = {
        guard let baseURL = URL(string: "https://audstreamer-backend-4cec188f37db.herokuapp.com/") else {
            preconditionFailure("Cannot init URL")
        }
        return baseURL
    }()
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(Int.self)
            let seconds: TimeInterval = Double(value) / 1000.0
            return Date(timeIntervalSince1970: seconds)
        }
        return decoder
    }()
}

// MARK: - Networking

extension DefaultAPIClient: Networking {
    func getEpisodes(from date: Date?) -> AnyPublisher<[EpisodeData], Error> {
        var url = baseURL.appendingPathComponent("episodes").appendingPathComponent("rss")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let date = date {
            let value = Int(date.timeIntervalSince1970 * 1000.0).description
            urlComponents?.queryItems = [URLQueryItem(name: "from_date", value: value)]
        }
        url = urlComponents?.url ?? url

        let request = getBaseURLRequest(for: url, method: .get)
        return session.dataTaskPublisher(for: request)
            .tryMap { [unowned self] data, response in
                try self.validateResponse(response)
                return self.replaceNoContentIfNeeded(response, bodyData: data)
            }
            .decode(type: [EpisodeData].self, decoder: decoder)
            .receive(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func addDevice(with notificationToken: String) -> AnyPublisher<Void, Error> {
        let url = baseURL.appendingPathComponent("devices")
        var request = getExtendedURLRequest(for: url, method: .post)
        request.httpBody = try? JSONEncoder().encode(["notificationToken": notificationToken])
        return session.dataTaskPublisher(for: request)
            .tryMap { [unowned self] in try self.validateResponse($0.response) }
            .receive(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }

    func deleteDevice() -> AnyPublisher<Void, Error> {
        let url = baseURL.appendingPathComponent("devices")
        let request = getExtendedURLRequest(for: url, method: .delete)
        return session.dataTaskPublisher(for: request)
            .tryMap { [unowned self] in try self.validateResponse($0.response) }
            .receive(on: Constant.defaultQueue)
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultAPIClient {
    private func getBaseURLRequest(for url: URL, method: HTTPMethod) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Constant.apiKey, forHTTPHeaderField: "X-Api-Key")
        return request
    }

    private func getExtendedURLRequest(for url: URL, method: HTTPMethod) -> URLRequest {
        var request = getBaseURLRequest(for: url, method: method)
        request.addValue(DeviceHelper.deviceID, forHTTPHeaderField: "X-Device-ID")
        if let authenticationToken = try? secureStore.getToken(),
           let tokenString = String(data: authenticationToken, encoding: .utf8) {
            request.addValue("Bearer \(tokenString)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    private func replaceNoContentIfNeeded(_ response: URLResponse, bodyData: Data) -> Data {
        guard let httpURLResponse = response as? HTTPURLResponse,
              httpURLResponse.statusCode == Constant.noContentHTTPStatus else {
            return bodyData
        }
        return Constant.emptyBodyString.data(using: .utf8) ?? bodyData
    }
}
