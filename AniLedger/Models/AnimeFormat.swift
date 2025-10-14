//
//  AnimeFormat.swift
//  AniLedger
//
//  Enum representing different anime formats
//

import Foundation

enum AnimeFormat: String, Codable, CaseIterable {
    case tv = "TV"
    case tvShort = "TV_SHORT"
    case movie = "MOVIE"
    case special = "SPECIAL"
    case ova = "OVA"
    case ona = "ONA"
    case music = "MUSIC"
}
