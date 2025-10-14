//
//  SkeletonView.swift
//  AniLedger
//
//  Skeleton loading views for content placeholders
//

import SwiftUI

// MARK: - Skeleton Modifier

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color.white.opacity(0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Views

struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Anime Card Skeleton

struct AnimeCardSkeleton: View {
    let width: CGFloat
    
    init(width: CGFloat = 150) {
        self.width = width
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image skeleton
            SkeletonView(width: width, height: width * 1.4, cornerRadius: 8)
            
            // Title skeleton
            SkeletonView(width: width, height: 12, cornerRadius: 4)
            SkeletonView(width: width * 0.7, height: 12, cornerRadius: 4)
        }
        .frame(width: width)
    }
}

// MARK: - Anime List Item Skeleton

struct AnimeListItemSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            // Cover image skeleton
            SkeletonView(width: 60, height: 84, cornerRadius: 6)
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(width: 200, height: 16, cornerRadius: 4)
                SkeletonView(width: 150, height: 12, cornerRadius: 4)
                SkeletonView(width: 180, height: 12, cornerRadius: 4)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Discover Section Skeleton

struct DiscoverSectionSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title skeleton
            SkeletonView(width: 200, height: 24, cornerRadius: 6)
                .padding(.horizontal)
            
            // Horizontal scrolling cards
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(0..<5, id: \.self) { _ in
                        AnimeCardSkeleton(width: 150)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 240)
        }
    }
}

// MARK: - Previews

#Preview("Skeleton View") {
    VStack(spacing: 20) {
        SkeletonView(width: 200, height: 20, cornerRadius: 8)
        SkeletonView(width: 150, height: 20, cornerRadius: 8)
        SkeletonView(width: 180, height: 20, cornerRadius: 8)
    }
    .padding()
}

#Preview("Anime Card Skeleton") {
    AnimeCardSkeleton(width: 150)
        .padding()
}

#Preview("Anime List Item Skeleton") {
    VStack(spacing: 12) {
        AnimeListItemSkeleton()
        AnimeListItemSkeleton()
        AnimeListItemSkeleton()
    }
    .padding()
}

#Preview("Discover Section Skeleton") {
    DiscoverSectionSkeleton()
        .padding(.vertical)
}
