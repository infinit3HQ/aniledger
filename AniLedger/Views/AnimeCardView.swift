import SwiftUI

struct AnimeCardView: View {
    let anime: Anime
    let width: CGFloat
    
    @State private var isHovered = false
    
    init(anime: Anime, width: CGFloat = 150) {
        self.anime = anime
        self.width = width
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImageView(
                url: anime.coverImage.large,
                width: width,
                height: width * 1.4
            )
            .cornerRadius(8)
            .shadow(radius: isHovered ? 8 : 2)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: isHovered ? 2 : 0)
            )
            
            Text(anime.title.preferred)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)
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
            episodes: 26,
            format: .tv,
            genres: ["Action", "Fantasy"],
            synopsis: "A boy fights demons to save his sister.",
            siteUrl: "https://anilist.co/anime/101922"
        )
    )
    .padding()
}
