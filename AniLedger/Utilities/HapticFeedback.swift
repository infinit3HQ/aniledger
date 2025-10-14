//
//  HapticFeedback.swift
//  AniLedger
//
//  Utility for providing haptic feedback on macOS
//

import AppKit

enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
    
    func trigger() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
        #endif
    }
    
    private var pattern: NSHapticFeedbackManager.FeedbackPattern {
        switch self {
        case .light, .selection:
            return .generic
        case .medium:
            return .alignment
        case .heavy:
            return .levelChange
        case .success:
            return .generic
        case .warning:
            return .alignment
        case .error:
            return .levelChange
        }
    }
}
