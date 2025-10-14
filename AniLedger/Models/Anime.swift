//
//  Anime.swift
//  AniLedger
//
//  Core domain model for anime
//

import Foundation

struct Anime: Identifiable, Codable {
    let id: Int
    let title: AnimeTitle
    let coverImage: CoverImage
    let episodes: Int?
    let format: AnimeFormat
    let genres: [String]
    let synopsis: String?
    let siteUrl: String
}
