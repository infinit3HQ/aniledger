//
//  GraphQLProtocols.swift
//  AniLedger
//
//  Created by Niraj Dilshan on 10/13/2025.
//

import Foundation

protocol GraphQLQuery {
    var queryString: String { get }
    var variables: [String: Any]? { get }
}

protocol GraphQLMutation {
    var mutationString: String { get }
    var variables: [String: Any] { get }
}
