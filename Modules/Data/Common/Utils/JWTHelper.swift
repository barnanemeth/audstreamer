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
    static func getPayload(from jwt: String) throws -> [String: Any] {
        let components = jwt.components(separatedBy: ".")
        guard components.indices.contains(1),
              let middleData = Data(base64Encoded: components[1]),
              let dictionary = try JSONSerialization.jsonObject(with: middleData, options: []) as? [String: Any] else {
            throw JWTError.badFormat
        }
        return dictionary
    }

    static func getSubject(from jwt: String) throws -> String? {
        try getPayload(from: jwt)["sub"] as? String
    }
}
