//
//  UserAnime.swift
//  AniLedger
//
//  Domain model for user-specific anime data
//

import Foundation

struct UserAnime: Identifiable {
    let id: Int
    let anime: Anime
    var status: AnimeStatus
    var progress: Int
    var score: Double?
    var sortOrder: Int
    var needsSync: Bool
    var lastModified: Date
}
