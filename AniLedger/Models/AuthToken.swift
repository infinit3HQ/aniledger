//
//  AuthToken.swift
//  AniLedger
//
//  Domain model for authentication token
//

import Foundation

struct AuthToken {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
}
