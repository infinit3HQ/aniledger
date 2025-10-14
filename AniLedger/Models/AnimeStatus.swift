//
//  AnimeStatus.swift
//  AniLedger
//
//  Enum representing user's anime watching status
//

import Foundation

enum AnimeStatus: String, Codable, CaseIterable {
    case watching = "CURRENT"
    case completed = "COMPLETED"
    case planToWatch = "PLANNING"
    case onHold = "PAUSED"
    case dropped = "DROPPED"
    
    var displayName: String {
        switch self {
        case .watching: return "Watching"
        case .completed: return "Completed"
        case .planToWatch: return "Plan to Watch"
        case .onHold: return "On Hold"
        case .dropped: return "Dropped"
        }
    }
}
