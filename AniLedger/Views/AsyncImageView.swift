import SwiftUI

struct AsyncImageView: View {
    let url: String?
    let width: CGFloat?
    let height: CGFloat?
    
    @State private var imageLoaded = false
    
    init(url: String?, width: CGFloat? = nil, height: CGFloat? = nil) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(imageLoaded ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.3)) {
                                    imageLoaded = true
                                }
                            }
                    case .failure:
                        errorView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                errorView
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
    
    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.2)
            ProgressView()
                .scaleEffect(0.8)
        }
        .shimmer()
    }
    
    private var errorView: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "photo")
                .foregroundColor(.gray)
                .font(.largeTitle)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AsyncImageView(url: "https://example.com/image.jpg", width: 150, height: 200)
        AsyncImageView(url: nil, width: 150, height: 200)
    }
    .padding()
}
