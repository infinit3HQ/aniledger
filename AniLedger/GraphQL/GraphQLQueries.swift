//
//  GraphQLQueries.swift
//  AniLedger
//
//  Created by Kiro on 10/13/2025.
//

import Foundation

struct FetchUserAnimeListQuery: GraphQLQuery {
    let userId: Int
    let status: String?
    
    var queryString: String {
        """
        query ($userId: Int, $status: MediaListStatus) {
          MediaListCollection(userId: $userId, type: ANIME, status: $status) {
            lists {
              entries {
                id
                status
                progress
                score
                media {
                  id
                  title {
                    romaji
                    english
                    native
                  }
                  coverImage {
                    large
                    medium
                  }
                  episodes
                  format
                  genres
                  description
                  siteUrl
                }
              }
            }
          }
        }
        """
    }
    
    var variables: [String: Any]? {
        var vars: [String: Any] = ["userId": userId]
        if let status = status {
            vars["status"] = status
        }
        return vars
    }
}

struct SearchAnimeQuery: GraphQLQuery {
    let searchTerm: String
    
    var queryString: String {
        """
        query ($search: String) {
          Page(page: 1, perPage: \(Config.searchResultsLimit)) {
            media(search: $search, type: ANIME) {
              id
              title {
                romaji
                english
                native
              }
              coverImage {
                large
                medium
              }
              episodes
              format
              genres
              description
              siteUrl
            }
          }
        }
        """
    }
    
    var variables: [String: Any]? {
        ["search": searchTerm]
    }
}

struct SeasonalAnimeQuery: GraphQLQuery {
    let season: String
    let year: Int
    
    var queryString: String {
        """
        query ($season: MediaSeason, $year: Int) {
          Page(page: 1, perPage: \(Config.discoverPageSize)) {
            media(season: $season, seasonYear: $year, type: ANIME, sort: POPULARITY_DESC) {
              id
              title {
                romaji
                english
                native
              }
              coverImage {
                large
                medium
              }
              episodes
              format
              genres
              description
              siteUrl
            }
          }
        }
        """
    }
    
    var variables: [String: Any]? {
        [
            "season": season,
            "year": year
        ]
    }
}

struct TrendingAnimeQuery: GraphQLQuery {
    var queryString: String {
        """
        query {
          Page(page: 1, perPage: \(Config.searchResultsLimit)) {
            media(type: ANIME, sort: TRENDING_DESC) {
              id
              title {
                romaji
                english
                native
              }
              coverImage {
                large
                medium
              }
              episodes
              format
              genres
              description
              siteUrl
            }
          }
        }
        """
    }
    
    var variables: [String: Any]? {
        nil
    }
}

struct FetchUserProfileQuery: GraphQLQuery {
    var queryString: String {
        """
        query {
          Viewer {
            id
            name
            avatar {
              large
              medium
            }
          }
        }
        """
    }
    
    var variables: [String: Any]? {
        nil
    }
}
