//
//  AiringStatusBadge.swift
//  AniLedger
//
//  Badge view showing when the next episode airs
//

import SwiftUI

struct AiringStatusBadge: View {
    let airingEpisode: AiringEpisode
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.caption2)
            
            Text(timeUntilAiringText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(airingColor)
        .cornerRadius(6)
    }
    
    private var timeUntilAiringText: String {
        let seconds = airingEpisode.timeUntilAiring
        let hours = seconds / 3600
        let days = hours / 24
        
        if days > 0 {
            return "Ep \(airingEpisode.episode) in \(days)d"
        } else if hours > 0 {
            return "Ep \(airingEpisode.episode) in \(hours)h"
        } else {
            let minutes = seconds / 60
            return "Ep \(airingEpisode.episode) in \(minutes)m"
        }
    }
    
    private var airingColor: Color {
        let hours = airingEpisode.timeUntilAiring / 3600
        
        if hours < 1 {
            return .red // Airing very soon
        } else if hours < 24 {
            return .orange // Airing today
        } else {
            return .blue // Airing later
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AiringStatusBadge(airingEpisode: AiringEpisode(
            airingAt: Int(Date().addingTimeInterval(1800).timeIntervalSince1970),
            timeUntilAiring: 1800, // 30 minutes
            episode: 5
        ))
        
        AiringStatusBadge(airingEpisode: AiringEpisode(
            airingAt: Int(Date().addingTimeInterval(7200).timeIntervalSince1970),
            timeUntilAiring: 7200, // 2 hours
            episode: 12
        ))
        
        AiringStatusBadge(airingEpisode: AiringEpisode(
            airingAt: Int(Date().addingTimeInterval(172800).timeIntervalSince1970),
            timeUntilAiring: 172800, // 2 days
            episode: 8
        ))
    }
    .padding()
}
