//
//  AniListAPIClient.swift
//  AniLedger
//
//  Created by Niraj Dilshan on 10/13/2025.
//

import Foundation

protocol AniListAPIClientProtocol {
    func execute<T: Decodable>(query: GraphQLQuery) async throws -> T
    func execute<T: Decodable>(mutation: GraphQLMutation) async throws -> T
}

class AniListAPIClient: AniListAPIClientProtocol {
    private let baseURL = URL(string: Config.apiEndpoint)!
    private let session: URLSession
    private let tokenProvider: () -> String?
    private let maxRetries = Config.maxSyncRetries
    private let initialRetryDelay: TimeInterval = Config.syncRetryDelay
    
    init(session: URLSession = .shared, tokenProvider: @escaping () -> String?) {
        self.session = session
        self.tokenProvider = tokenProvider
    }
    
    // MARK: - Public Methods
    
    func execute<T: Decodable>(query: GraphQLQuery) async throws -> T {
        let requestBody = GraphQLRequestBody(
            query: query.queryString,
            variables: query.variables
        )
        return try await executeRequest(body: requestBody)
    }
    
    func execute<T: Decodable>(mutation: GraphQLMutation) async throws -> T {
        let requestBody = GraphQLRequestBody(
            query: mutation.mutationString,
            variables: mutation.variables
        )
        return try await executeRequest(body: requestBody)
    }
    
    // MARK: - Private Methods
    
    private func executeRequest<T: Decodable>(body: GraphQLRequestBody, retryCount: Int = 0) async throws -> T {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30 // 30 second timeout
        
        // Add authorization header if token is available
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode request body
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw KiroError.decodingError(underlying: error)
        }
        
        // Execute request with error handling
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Handle specific network errors
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    throw KiroError.noInternetConnection
                case NSURLErrorTimedOut:
                    throw KiroError.timeout
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    throw KiroError.serverUnavailable
                default:
                    throw KiroError.networkError(underlying: error)
                }
            }
            throw KiroError.networkError(underlying: error)
        }
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KiroError.invalidResponse
        }
        
        // Handle rate limiting with retry
        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            
            if retryCount < maxRetries {
                let delay = retryAfter ?? (initialRetryDelay * pow(2.0, Double(retryCount)))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeRequest(body: body, retryCount: retryCount + 1)
            } else {
                throw KiroError.rateLimitExceeded(retryAfter: retryAfter)
            }
        }
        
        // Handle server errors with retry
        if (500...599).contains(httpResponse.statusCode) {
            if retryCount < maxRetries {
                let delay = initialRetryDelay * pow(2.0, Double(retryCount))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeRequest(body: body, retryCount: retryCount + 1)
            } else {
                throw KiroError.serverUnavailable
            }
        }
        
        // Handle authentication errors
        if httpResponse.statusCode == 401 {
            throw KiroError.authenticationFailed(reason: "Session expired or invalid token")
        }
        
        // Handle other HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw KiroError.apiError(message: errorMessage, statusCode: httpResponse.statusCode)
        }
        
        // Decode GraphQL response
        let graphQLResponse: GraphQLResponse<T>
        do {
            graphQLResponse = try JSONDecoder().decode(GraphQLResponse<T>.self, from: data)
        } catch {
            throw KiroError.decodingError(underlying: error)
        }
        
        // Check for GraphQL errors
        if let errors = graphQLResponse.errors, !errors.isEmpty {
            let errorMessage = errors.map { $0.message }.joined(separator: ", ")
            let statusCode = errors.first?.status
            
            // Handle specific GraphQL error types
            if errorMessage.lowercased().contains("authentication") || errorMessage.lowercased().contains("unauthorized") {
                throw KiroError.authenticationFailed(reason: errorMessage)
            }
            
            throw KiroError.apiError(message: errorMessage, statusCode: statusCode)
        }
        
        // Return data if available
        guard let data = graphQLResponse.data else {
            throw KiroError.apiError(message: "No data in response", statusCode: nil)
        }
        
        return data
    }
}

// MARK: - Request Body Model

private struct GraphQLRequestBody: Encodable {
    let query: String
    let variables: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case query
        case variables
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(query, forKey: .query)
        
        if let variables = variables {
            let jsonData = try JSONSerialization.data(withJSONObject: variables)
            let jsonObject = try JSONDecoder().decode(AnyCodable.self, from: jsonData)
            try container.encode(jsonObject, forKey: .variables)
        }
    }
}

// MARK: - AnyCodable Helper

private struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable value cannot be encoded"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
