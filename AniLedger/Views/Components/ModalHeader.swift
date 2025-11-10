//
//  ModalHeader.swift
//  AniLedger
//
//  Reusable modal header component with consistent styling
//

import SwiftUI

/// Standard modal header with title and close button
struct ModalHeader: View {
    let title: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                ModalCloseButton(action: onDismiss)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
        }
    }
}

/// Reusable close button for modals with consistent styling
struct ModalCloseButton: View {
    let action: () -> Void
    var style: CloseButtonStyle = .filled
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(fontSize)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.cancelAction)
    }
    
    private var iconName: String {
        switch style {
        case .filled:
            return "xmark.circle.fill"
        case .plain:
            return "xmark"
        }
    }
    
    private var fontSize: Font {
        switch style {
        case .filled:
            return .title2
        case .plain:
            return .system(size: 11, weight: .semibold)
        }
    }
    
    enum CloseButtonStyle {
        case filled  // xmark.circle.fill - for headers
        case plain   // xmark - for overlays
    }
}

#Preview {
    ModalHeader(title: "Settings") {
        print("Dismissed")
    }
}
