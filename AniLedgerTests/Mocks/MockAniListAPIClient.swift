//
//  MockAniListAPIClient.swift
//  AniLedgerTests
//
//  Created by Kiro on 10/13/2025.
//

import Foundation
@testable import AniLedger

class MockAniListAPIClient: AniListAPIClientProtocol {
    var executeQueryCallCount = 0
    var executeMutationCallCount = 0
    
    var queryResult: Any?
    var mutationResult: Any?
    var shouldThrowError: Error?
    
    func execute<T: Decodable>(query: GraphQLQuery) async throws -> T {
        executeQueryCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        guard let result = queryResult as? T else {
            throw KiroError.invalidResponse
        }
        
        return result
    }
    
    func execute<T: Decodable>(mutation: GraphQLMutation) async throws -> T {
        executeMutationCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        guard let result = mutationResult as? T else {
            throw KiroError.invalidResponse
        }
        
        return result
    }
    
    func reset() {
        executeQueryCallCount = 0
        executeMutationCallCount = 0
        queryResult = nil
        mutationResult = nil
        shouldThrowError = nil
    }
}
