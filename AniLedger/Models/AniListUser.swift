//
//  AniListUser.swift
//  AniLedger
//
//  Domain model for AniList user
//

import Foundation

struct AniListUser: Codable {
    let id: Int
    let name: String
    let avatar: UserAvatar?
}

struct UserAvatar: Codable {
    let large: String?
    let medium: String?
}
