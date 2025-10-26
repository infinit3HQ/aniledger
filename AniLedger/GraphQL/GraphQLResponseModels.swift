//
//  GraphQLResponseModels.swift
//  AniLedger
//
//  Created by Kiro on 10/13/2025.
//

import Foundation

// MARK: - Base Response Models

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
    let status: Int?
    let locations: [ErrorLocation]?
}

struct ErrorLocation: Decodable {
    let line: Int
    let column: Int
}

// MARK: - Media List Collection Response

struct MediaListCollectionResponse: Decodable {
    let MediaListCollection: MediaListCollection
}

struct MediaListCollection: Decodable {
    let lists: [MediaList]
}

struct MediaList: Decodable {
    let entries: [MediaListEntry]
}

struct MediaListEntry: Decodable {
    let id: Int
    let status: String
    let progress: Int
    let score: Double?
    let media: MediaResponse
}

// MARK: - Media Response

struct MediaResponse: Decodable {
    let id: Int
    let title: TitleResponse
    let coverImage: CoverImageResponse
    let episodes: Int?
    let format: String?
    let genres: [String]
    let description: String?
    let siteUrl: String
}

struct TitleResponse: Decodable {
    let romaji: String
    let english: String?
    let native: String?
}

struct CoverImageResponse: Decodable {
    let large: String
    let medium: String
}

// MARK: - Page Response (for Search, Seasonal, Trending)

struct PageResponse: Decodable {
    let Page: Page
}

struct Page: Decodable {
    let media: [MediaResponse]
}

// MARK: - User Profile Response

struct ViewerResponse: Decodable {
    let Viewer: UserResponse
}

struct UserResponse: Decodable {
    let id: Int
    let name: String
    let avatar: AvatarResponse?
}

struct AvatarResponse: Decodable {
    let large: String?
    let medium: String?
}

// MARK: - Mutation Response

struct SaveMediaListEntryResponse: Decodable {
    let SaveMediaListEntry: SimplifiedMediaListEntry
}

struct SimplifiedMediaListEntry: Decodable {
    let id: Int
    let status: String?
    let progress: Int?
    let score: Double?
    let media: SimplifiedMediaResponse
}

struct SimplifiedMediaResponse: Decodable {
    let id: Int
}
