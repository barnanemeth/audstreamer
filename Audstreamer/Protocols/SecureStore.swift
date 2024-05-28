//
//  SecureStore.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 17..
//

import Foundation

protocol SecureStore {
    func storeToken(_ token: Data) throws
    func getToken() throws -> Data
    func deleteToken() throws
}
