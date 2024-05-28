//
//  JWTHelper.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 26..
//

import Foundation

enum JWTError: Error {
    case badFormat
}

enum JWTHelper {
    static func getPayload(from data: Data) throws -> [String: Any] {
        guard let tokenString = String(data: data, encoding: .utf8) else { throw JWTError.badFormat }
        let components = tokenString.components(separatedBy: ".")
        guard components.indices.contains(1),
              let middleData = Data(base64Encoded: components[1]),
              let dictionary = try JSONSerialization.jsonObject(with: middleData, options: []) as? [String: Any] else {
            throw JWTError.badFormat
        }
        return dictionary
    }

    static func getSubject(from data: Data) throws -> String? {
        try getPayload(from: data)["sub"] as? String
    }
}
