//
//  MockSyncService.swift
//  AniLedgerTests
//
//  Mock implementation of SyncServiceProtocol for testing
//

import Foundation
@testable import AniLedger

class MockSyncService: SyncServiceProtocol {
    var syncAllCallCount = 0
    var syncUserListsCallCount = 0
    var processSyncQueueCallCount = 0
    var queueOperationCallCount = 0
    
    var queuedOperations: [SyncOperation] = []
    var shouldThrowError: Error?
    
    func syncAll() async throws {
        syncAllCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
    }
    
    func syncUserLists() async throws {
        syncUserListsCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
    }
    
    func processSyncQueue() async throws {
        processSyncQueueCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
    }
    
    func queueOperation(_ operation: SyncOperation) {
        queueOperationCallCount += 1
        queuedOperations.append(operation)
    }
    
    func reset() {
        syncAllCallCount = 0
        syncUserListsCallCount = 0
        processSyncQueueCallCount = 0
        queueOperationCallCount = 0
        queuedOperations = []
        shouldThrowError = nil
    }
}
