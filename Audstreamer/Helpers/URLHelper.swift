//
//  URLHelper.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 05..
//

import Foundation
import Combine

enum URLHelper {

    // MARK: Constants

    private enum Constant {
        static let subDirectory = "Downloads"
        static let httpMethodForContentLength = "HEAD"
        static let headerKeyForContentLength = "Content-Length"
        static let receiveQueue = DispatchQueue.main
    }

    // MARK: Private properties

    private static let fileManager = FileManager.default

    // MARK: Properties

    static var documentDirectory: URL? {
        guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return directoryURL
    }
    static var destinationDirectory: URL? {
        documentDirectory?.appendingPathComponent(Constant.subDirectory)
    }
}

// MARK: - Public methods

extension URLHelper {
    static func contentLength(of url: URL?) async throws -> Int {
        guard let url = url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = Constant.httpMethodForContentLength

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              let lengthString = httpResponse.allHeaderFields[Constant.headerKeyForContentLength] as? String,
              let length = Int(lengthString) else {
            throw URLError(.badServerResponse)
        }
        return length
    }
}
