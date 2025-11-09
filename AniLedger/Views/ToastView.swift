//
//  ToastView.swift
//  AniLedger
//
//  Toast notification view for displaying brief messages
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success
        case error
        case warning
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.title3)
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if let toast = toast {
                        VStack {
                            ToastView(message: toast.message, type: toast.type)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            Spacer()
                        }
                        .padding(.top, 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: self.toast != nil)
                        .onAppear {
                            scheduleToastDismissal()
                        }
                        .onTapGesture {
                            dismissToast()
                        }
                    }
                }
            )
            .onChange(of: toast) {
                scheduleToastDismissal()
            }
    }
    
    private func scheduleToastDismissal() {
        workItem?.cancel()
        
        let task = DispatchWorkItem {
            dismissToast()
        }
        
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
    }
    
    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        workItem?.cancel()
        workItem = nil
    }
}

// MARK: - Toast Model

struct Toast: Equatable {
    let message: String
    let type: ToastView.ToastType
    
    static func success(_ message: String) -> Toast {
        Toast(message: message, type: .success)
    }
    
    static func error(_ message: String) -> Toast {
        Toast(message: message, type: .error)
    }
    
    static func warning(_ message: String) -> Toast {
        Toast(message: message, type: .warning)
    }
    
    static func info(_ message: String) -> Toast {
        Toast(message: message, type: .info)
    }
}

extension View {
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ToastView(message: "Successfully synced your library", type: .success)
        ToastView(message: "Failed to connect to server", type: .error)
        ToastView(message: "Rate limit exceeded", type: .warning)
        ToastView(message: "New update available", type: .info)
    }
    .padding()
}
