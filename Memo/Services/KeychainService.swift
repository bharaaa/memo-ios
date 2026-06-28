//
//  KeychainService.swift
//  Memo
//
//  A simple wrapper for securely storing API keys in the Keychain.
//

import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data
        ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    func saveString(_ value: String, forKey key: String) -> OSStatus {
        guard let data = value.data(using: .utf8) else {
            return errSecParam
        }
        return save(key: key, data: data)
    }
    
    func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ] as [String : Any]
        
        var dataTypeRef: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }
    
    func loadString(forKey key: String) -> String? {
        if let data = load(key: key) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    @discardableResult
    func delete(key: String) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key
        ] as [String : Any]
        
        return SecItemDelete(query as CFDictionary)
    }
}
