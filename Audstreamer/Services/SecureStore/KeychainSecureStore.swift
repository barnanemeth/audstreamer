//
//  Keychain.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 17..
//

import Foundation

final class KeychainSecureStore: SecureStore {

    // MARK: - Properties

    private let tokenApplicationTag = "hu.barnanemeth.dev.Audstreamer.userToken"

    // MARK: - Private methods

    private func saveKey(_ key: Data, applicationTag: String) throws {
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: applicationTag,
            kSecValueData: key,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as NSMutableDictionary

        let osStatus = SecItemAdd(query, nil)

        try throwOSStatus(osStatus)
    }

    private func updateKey(_ key: Data, applicationTag: String) throws {
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: applicationTag,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as NSMutableDictionary

        let osStatus = SecItemUpdate(query, [kSecValueData: key] as NSDictionary)

        try throwOSStatus(osStatus)
    }

    private func deleteKey(applicationTag: String) throws {
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: applicationTag
        ] as NSMutableDictionary

        let osStatus = SecItemDelete(query)

        try throwOSStatus(osStatus)
    }

    private func getKey(applicationTag: String) throws -> Data {
        var result: CFTypeRef?
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: applicationTag,
            kSecReturnData: true
        ] as NSMutableDictionary

        let osStatus = SecItemCopyMatching(query, &result)

        switch osStatus {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(errSecMissingValue), userInfo: nil)
            }

            return data
        default:
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(osStatus), userInfo: nil)
        }
    }

    private func throwOSStatus(_ err: OSStatus) throws {
        guard err == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(err), userInfo: nil)
        }
    }

    // MARK: - Public methods

    func storeToken(_ token: Data) throws {
        do {
            try saveKey(token, applicationTag: tokenApplicationTag)
        } catch {
            try updateKey(token, applicationTag: tokenApplicationTag)
        }
    }

    func getToken() throws -> Data {
        try getKey(applicationTag: tokenApplicationTag)
    }

    func deleteToken() throws {
        try deleteKey(applicationTag: tokenApplicationTag)
    }
}
