import Foundation
import Security

/// Protocol defining keychain operations for secure token storage
protocol KeychainManagerProtocol {
    func save(token: String, for key: String) throws
    func retrieve(for key: String) throws -> String?
    func delete(for key: String) throws
}

/// Manager class for secure storage of authentication tokens in the Keychain
class KeychainManager: KeychainManagerProtocol {
    
    // Service identifier for Keychain items - using Config constant
    private let serviceIdentifier = Config.keychainService
    
    // MARK: - Keychain Operations
    
    /// Save a token to the Keychain
    /// - Parameters:
    ///   - token: The token string to save
    ///   - key: The key to associate with the token
    /// - Throws: KeychainError if the operation fails
    func save(token: String, for key: String) throws {
        guard let tokenData = token.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // Check if item already exists
        let existingItemQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        
        // Try to delete existing item first
        SecItemDelete(existingItemQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }
    
    /// Retrieve a token from the Keychain
    /// - Parameter key: The key associated with the token
    /// - Returns: The token string if found, nil otherwise
    /// - Throws: KeychainError if the operation fails
    func retrieve(for key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Item not found is not an error, just return nil
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status: status)
        }
        
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return token
    }
    
    /// Delete a token from the Keychain
    /// - Parameter key: The key associated with the token to delete
    /// - Throws: KeychainError if the operation fails
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Item not found is not an error for deletion
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
}

// MARK: - Keychain Error

/// Errors that can occur during Keychain operations
enum KeychainError: LocalizedError {
    case invalidData
    case saveFailed(status: OSStatus)
    case retrieveFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format for Keychain operation"
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve from Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        }
    }
}
