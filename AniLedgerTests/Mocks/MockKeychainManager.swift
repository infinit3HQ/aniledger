//
//  MockKeychainManager.swift
//  AniLedgerTests
//
//  Created by Kiro on 10/13/2025.
//

import Foundation
@testable import AniLedger

class MockKeychainManager: KeychainManagerProtocol {
    private var storage: [String: String] = [:]
    
    var saveCallCount = 0
    var retrieveCallCount = 0
    var deleteCallCount = 0
    
    var shouldThrowOnSave = false
    var shouldThrowOnRetrieve = false
    var shouldThrowOnDelete = false
    
    func save(token: String, for key: String) throws {
        saveCallCount += 1
        
        if shouldThrowOnSave {
            throw KeychainError.saveFailed(status: -1)
        }
        
        storage[key] = token
    }
    
    func retrieve(for key: String) throws -> String? {
        retrieveCallCount += 1
        
        if shouldThrowOnRetrieve {
            throw KeychainError.retrieveFailed(status: -1)
        }
        
        return storage[key]
    }
    
    func delete(for key: String) throws {
        deleteCallCount += 1
        
        if shouldThrowOnDelete {
            throw KeychainError.deleteFailed(status: -1)
        }
        
        storage.removeValue(forKey: key)
    }
    
    func reset() {
        storage.removeAll()
        saveCallCount = 0
        retrieveCallCount = 0
        deleteCallCount = 0
        shouldThrowOnSave = false
        shouldThrowOnRetrieve = false
        shouldThrowOnDelete = false
    }
}
