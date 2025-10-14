import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Convenience initializers for common empty states
extension EmptyStateView {
    static func emptyLibrary(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "rectangle.stack.badge.plus",
            title: "Your Library is Empty",
            message: "Start building your anime collection by discovering new shows or searching for your favorites.",
            actionTitle: "Discover Anime",
            action: action
        )
    }
    
    static func emptyWatchingList() -> EmptyStateView {
        EmptyStateView(
            icon: "play.circle",
            title: "Nothing Currently Watching",
            message: "Add anime you're currently watching to keep track of your progress."
        )
    }
    
    static func emptyCompletedList() -> EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "No Completed Anime",
            message: "Anime you've finished watching will appear here."
        )
    }
    
    static func emptyPlanToWatchList() -> EmptyStateView {
        EmptyStateView(
            icon: "bookmark",
            title: "No Planned Anime",
            message: "Add anime you want to watch in the future to this list."
        )
    }
    
    static func emptyOnHoldList() -> EmptyStateView {
        EmptyStateView(
            icon: "pause.circle",
            title: "No Anime On Hold",
            message: "Anime you've paused will appear here."
        )
    }
    
    static func emptyDroppedList() -> EmptyStateView {
        EmptyStateView(
            icon: "xmark.circle",
            title: "No Dropped Anime",
            message: "Anime you've dropped will appear here."
        )
    }
    
    static func noSearchResults() -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search terms or filters."
        )
    }
    
    static func noDiscoverContent(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Unable to Load Content",
            message: "We couldn't fetch the latest anime. Please check your connection and try again.",
            actionTitle: "Retry",
            action: action
        )
    }
    
    static func offline() -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "You're Offline",
            message: "Connect to the internet to discover new anime and sync your library."
        )
    }
}

#Preview("Empty Library") {
    EmptyStateView.emptyLibrary {
        print("Discover tapped")
    }
}

#Preview("Empty Watching List") {
    EmptyStateView.emptyWatchingList()
}

#Preview("Empty Completed List") {
    EmptyStateView.emptyCompletedList()
}

#Preview("No Search Results") {
    EmptyStateView.noSearchResults()
}

#Preview("Custom Empty State") {
    EmptyStateView(
        icon: "star.fill",
        title: "Custom Empty State",
        message: "This is a custom empty state with an action button.",
        actionTitle: "Take Action",
        action: {
            print("Action tapped")
        }
    )
}

#Preview("Offline State") {
    EmptyStateView.offline()
}

#Preview("No Discover Content") {
    EmptyStateView.noDiscoverContent {
        print("Retry tapped")
    }
}
