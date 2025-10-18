//
//  AniListUser.swift
//  AniLedger
//
//  Domain model for AniList user
//

import Foundation

struct AniListUser: Codable, Equatable {
    let id: Int
    let name: String
    let avatar: UserAvatar?
}

struct UserAvatar: Codable, Equatable {
    let large: String?
    let medium: String?
}
