import SwiftUI

struct AnimeCardView: View {
    let anime: Anime
    let width: CGFloat
    let userStatus: AnimeStatus?
    
    @State private var isHovered = false
    
    init(anime: Anime, width: CGFloat = 150, userStatus: AnimeStatus? = nil) {
        self.anime = anime
        self.width = width
        self.userStatus = userStatus
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImageView(
                    url: anime.coverImage.large,
                    width: width,
                    height: width * 1.4
                )
                .frame(width: width, height: width * 1.4)
                .cornerRadius(8)
                .shadow(radius: isHovered ? 8 : 2)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: isHovered ? 2 : 0)
                )
                
                if let status = userStatus {
                    HStack(spacing: 3) {
                        Image(systemName: status.iconName)
                            .font(.system(size: 8))
                        Text(status.displayName)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(status.color.opacity(0.9))
                            .shadow(radius: 2)
                    )
                    .padding(6)
                }
            }
            
            Text(anime.title.preferred)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: width, height: 28, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: width)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    AnimeCardView(
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
            bannerImage: nil,
            episodes: 26,
            format: .tv,
            genres: ["Action", "Fantasy"],
            synopsis: "A boy fights demons to save his sister.",
            siteUrl: "https://anilist.co/anime/101922"
        )
    )
    .padding()
}
