import SwiftUI

struct LoadingView: View {
    let message: String?
    let size: LoadingSize
    
    init(message: String? = nil, size: LoadingSize = .medium) {
        self.message = message
        self.size = size
    }
    
    enum LoadingSize {
        case small
        case medium
        case large
        
        var progressViewSize: ControlSize {
            switch self {
            case .small: return .small
            case .medium: return .regular
            case .large: return .large
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .body
            }
        }
    }
    
    var body: some View {
        VStack(spacing: size.spacing) {
            ProgressView()
                .controlSize(size.progressViewSize)
                .scaleEffect(size == .large ? 1.5 : 1.0)
                .frame(width: 40, height: 40)
            
            if let message = message {
                Text(message)
                    .font(size.fontSize)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingOverlayView: View {
    let message: String?
    
    init(message: String? = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .scaleEffect(1.5)
                    .frame(width: 40, height: 40)
                
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

struct InlineLoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .frame(width: 20, height: 20)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview("Small Loading") {
    LoadingView(message: "Loading...", size: .small)
        .frame(width: 300, height: 200)
}

#Preview("Medium Loading") {
    LoadingView(message: "Fetching anime data...", size: .medium)
        .frame(width: 300, height: 200)
}

#Preview("Large Loading") {
    LoadingView(message: "Syncing with AniList...", size: .large)
        .frame(width: 300, height: 200)
}

#Preview("Loading without Message") {
    LoadingView(size: .medium)
        .frame(width: 300, height: 200)
}

#Preview("Loading Overlay") {
    ZStack {
        Color.blue.ignoresSafeArea()
        
        LoadingOverlayView(message: "Syncing...")
    }
}

#Preview("Inline Loading") {
    VStack {
        Text("Content Above")
        InlineLoadingView(message: "Loading more...")
        Text("Content Below")
    }
}
