//
//  AnimeStatus.swift
//  AniLedger
//
//  Enum representing user's anime watching status
//

import Foundation
import SwiftUI

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
    
    var iconName: String {
        switch self {
        case .watching: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .planToWatch: return "bookmark.fill"
        case .onHold: return "pause.circle.fill"
        case .dropped: return "xmark.circle.fill"
        }
    }
    
    var color: SwiftUI.Color {
        switch self {
        case .watching: return .green
        case .completed: return .blue
        case .planToWatch: return .purple
        case .onHold: return .orange
        case .dropped: return .red
        }
    }
}
