import SwiftUI

struct ProgressIndicatorView: View {
    let current: Int
    let total: Int?
    let compact: Bool
    
    init(current: Int, total: Int?, compact: Bool = false) {
        self.current = current
        self.total = total
        self.compact = compact
    }
    
    var progressText: String {
        if let total = total {
            return "\(current)/\(total)"
        } else {
            return "\(current)"
        }
    }
    
    var progressPercentage: Double? {
        guard let total = total, total > 0 else { return nil }
        return Double(current) / Double(total)
    }
    
    var body: some View {
        if compact {
            compactView
        } else {
            standardView
        }
    }
    
    private var compactView: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.circle.fill")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(progressText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var standardView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Episode Progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(progressText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
            }
            
            if let percentage = progressPercentage {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * percentage, height: 8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: percentage)
                    }
                }
                .frame(height: 8)
            }
        }
    }
}

#Preview("Standard with Total") {
    ProgressIndicatorView(current: 5, total: 12)
        .padding()
        .frame(width: 300)
}

#Preview("Standard without Total") {
    ProgressIndicatorView(current: 15, total: nil)
        .padding()
        .frame(width: 300)
}

#Preview("Compact with Total") {
    ProgressIndicatorView(current: 5, total: 12, compact: true)
        .padding()
}

#Preview("Compact without Total") {
    ProgressIndicatorView(current: 15, total: nil, compact: true)
        .padding()
}
