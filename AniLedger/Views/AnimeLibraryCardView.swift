//
//  AnimeLibraryCardView.swift
//  AniLedger
//
//  Card view for displaying anime in the library with progress and status info
//

import SwiftUI

struct AnimeLibraryCardView: View {
    let userAnime: UserAnime
    let width: CGFloat
    
    @State private var isHovered = false
    
    init(userAnime: UserAnime, width: CGFloat = 160) {
        self.userAnime = userAnime
        self.width = width
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover Image with Progress Overlay
            ZStack(alignment: .bottom) {
                AsyncImageView(
                    url: userAnime.anime.coverImage.large,
                    width: width,
                    height: width * 1.5
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(isHovered ? 0.3 : 0.15), radius: isHovered ? 12 : 6, y: isHovered ? 6 : 3)
                
                // Progress Bar Overlay
                if let totalEpisodes = userAnime.anime.episodes, totalEpisodes > 0 {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Progress Info
                        HStack {
                            Text("\(userAnime.progress)/\(totalEpisodes)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(.black.opacity(0.7))
                                )
                            
                            Spacer()
                            
                            // Score Badge
                            if let score = userAnime.score, score > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                    Text(String(format: "%.1f", score))
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(.black.opacity(0.7))
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(.black.opacity(0.3))
                                
                                Rectangle()
                                    .fill(progressColor)
                                    .frame(width: geometry.size.width * progressPercentage)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                
                // Sync Indicator
                if userAnime.needsSync {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(.orange)
                                )
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: width, height: width * 1.5)
            
            // Title and Info
            VStack(alignment: .leading, spacing: 4) {
                Text(userAnime.anime.title.preferred)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .top)
                
                Text(formatDisplayName(userAnime.anime.format))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: width, alignment: .leading)
            .padding(.top, 8)
        }
        .frame(width: width)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                HapticFeedback.selection.trigger()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var progressPercentage: CGFloat {
        guard let total = userAnime.anime.episodes, total > 0 else { return 0 }
        return CGFloat(userAnime.progress) / CGFloat(total)
    }
    
    private var progressColor: Color {
        let percentage = progressPercentage
        if percentage >= 1.0 {
            return .green
        } else if percentage >= 0.5 {
            return .blue
        } else {
            return .orange
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDisplayName(_ format: AnimeFormat) -> String {
        switch format {
        case .tv: return "TV"
        case .tvShort: return "TV Short"
        case .movie: return "Movie"
        case .special: return "Special"
        case .ova: return "OVA"
        case .ona: return "ONA"
        case .music: return "Music"
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        AnimeLibraryCardView(
            userAnime: UserAnime(
                id: 1,
                anime: Anime(
                    id: 1,
                    title: AnimeTitle(
                        romaji: "Kimetsu no Yaiba",
                        english: "Demon Slayer",
                        native: "鬼滅の刃"
                    ),
                    coverImage: CoverImage(
                        large: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101922-PEn1CTc93blC.jpg",
                        medium: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx101922-PEn1CTc93blC.jpg"
                    ),
                    episodes: 26,
                    format: .tv,
                    genres: ["Action", "Fantasy"],
                    synopsis: "A boy fights demons.",
                    siteUrl: "https://anilist.co/anime/101922"
                ),
                status: .watching,
                progress: 15,
                score: 9.5,
                sortOrder: 0,
                needsSync: false,
                lastModified: Date()
            )
        )
        
        AnimeLibraryCardView(
            userAnime: UserAnime(
                id: 2,
                anime: Anime(
                    id: 2,
                    title: AnimeTitle(
                        romaji: "Shingeki no Kyojin",
                        english: "Attack on Titan",
                        native: "進撃の巨人"
                    ),
                    coverImage: CoverImage(
                        large: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-C6FPmWm59CyP.jpg",
                        medium: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx16498-C6FPmWm59CyP.jpg"
                    ),
                    episodes: 25,
                    format: .tv,
                    genres: ["Action", "Drama"],
                    synopsis: "Humanity fights titans.",
                    siteUrl: "https://anilist.co/anime/16498"
                ),
                status: .watching,
                progress: 25,
                score: 10.0,
                sortOrder: 1,
                needsSync: true,
                lastModified: Date()
            )
        )
    }
    .padding()
}
