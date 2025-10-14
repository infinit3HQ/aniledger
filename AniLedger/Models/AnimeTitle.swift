//
//  AnimeTitle.swift
//  AniLedger
//
//  Core domain model for anime titles
//

import Foundation

struct AnimeTitle: Codable {
    let romaji: String
    let english: String?
    let native: String?
    
    var preferred: String {
        english ?? romaji
    }
}
