import Foundation
import Security

struct KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    // Save or update an item in the keychain
    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        // Try to add the item
        let status = SecItemAdd(query, nil)
        
        // If it already exists, update it
        if status == errSecDuplicateItem {
            let updateQuery = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account
            ] as CFDictionary
            
            let attributesToUpdate = [kSecValueData: data] as CFDictionary
            
            SecItemUpdate(updateQuery, attributesToUpdate)
        }
    }
    
    // Read an item from the keychain
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    // Delete an item from the keychain
    func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        SecItemDelete(query)
    }
    
    // Convenience methods for saving and reading Strings
    func save(_ text: String, service: String, account: String) {
        guard let data = text.data(using: .utf8) else { return }
        save(data, service: service, account: account)
    }
    
    func read(service: String, account: String) -> String? {
        let data: Data? = read(service: service, account: account)
        guard let validData = data else { return nil }
        return String(data: validData, encoding: .utf8)
    }
}
