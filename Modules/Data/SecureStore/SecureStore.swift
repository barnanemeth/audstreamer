//
//  SecureStore.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 17..
//

import Foundation

protocol SecureStore: Sendable {
    func storeToken(_ token: String) throws
    func getToken() throws -> String
    func deleteToken() throws
}
