import SwiftUI

struct GenreTagView: View {
    let genre: String
    let isSelected: Bool
    let action: (() -> Void)?
    
    @State private var isHovered = false
    
    init(genre: String, isSelected: Bool = false, action: (() -> Void)? = nil) {
        self.genre = genre
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: {
                    HapticFeedback.selection.trigger()
                    action()
                }) {
                    tagContent
                }
                .buttonStyle(.plain)
            } else {
                tagContent
            }
        }
    }
    
    private var tagContent: some View {
        Text(genre)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(isHovered ? 0.3 : 0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.accentColor : (isHovered ? Color.accentColor.opacity(0.5) : Color.clear),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

struct GenreTagsView: View {
    let genres: [String]
    let selectedGenres: Set<String>
    let onGenreTap: ((String) -> Void)?
    
    init(genres: [String], selectedGenres: Set<String> = [], onGenreTap: ((String) -> Void)? = nil) {
        self.genres = genres
        self.selectedGenres = selectedGenres
        self.onGenreTap = onGenreTap
    }
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(genres, id: \.self) { genre in
                GenreTagView(
                    genre: genre,
                    isSelected: selectedGenres.contains(genre),
                    action: onGenreTap != nil ? { onGenreTap?(genre) } : nil
                )
            }
        }
    }
}

// Simple flow layout for wrapping genre tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview("Single Tag") {
    GenreTagView(genre: "Action")
        .padding()
}

#Preview("Selected Tag") {
    GenreTagView(genre: "Fantasy", isSelected: true)
        .padding()
}

#Preview("Multiple Tags") {
    GenreTagsView(
        genres: ["Action", "Adventure", "Comedy", "Drama", "Fantasy", "Romance", "Sci-Fi", "Slice of Life"],
        selectedGenres: ["Action", "Fantasy"]
    )
    .padding()
    .frame(width: 300)
}

#Preview("Interactive Tags") {
    GenreTagsView(
        genres: ["Action", "Adventure", "Comedy", "Drama"],
        selectedGenres: ["Action"],
        onGenreTap: { genre in
            print("Tapped: \(genre)")
        }
    )
    .padding()
    .frame(width: 300)
}
