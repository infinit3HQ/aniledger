//
//  KiroError.swift
//  AniLedger
//
//  Created by Kiro on 10/13/2025.
//

import Foundation
import SwiftUI

enum KiroError: LocalizedError {
    case authenticationFailed(reason: String)
    case networkError(underlying: Error)
    case apiError(message: String, statusCode: Int?)
    case decodingError(underlying: Error)
    case coreDataError(underlying: Error)
    case keychainError(status: OSStatus)
    case syncConflict(localItem: UserAnime, remoteItem: UserAnime)
    case rateLimitExceeded
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message, let code):
            if let code = code {
                return "API error (\(code)): \(message)"
            }
            return "API error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .coreDataError(let error):
            return "Database error occurred: \(error.localizedDescription)"
        case .keychainError(let status):
            return "Keychain access error (status: \(status))"
        case .syncConflict:
            return "Sync conflict detected. Remote changes will be applied."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .authenticationFailed:
            return "Unable to authenticate with AniList"
        case .networkError:
            return "Network connection issue"
        case .apiError:
            return "AniList API returned an error"
        case .decodingError:
            return "Data format error"
        case .coreDataError:
            return "Local database error"
        case .keychainError:
            return "Secure storage error"
        case .syncConflict:
            return "Data conflict between local and remote"
        case .rateLimitExceeded:
            return "Too many requests"
        case .invalidResponse:
            return "Server response error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Please try logging in again"
        case .networkError:
            return "Check your internet connection and try again"
        case .apiError:
            return "Please try again later"
        case .decodingError:
            return "Please update the app or contact support"
        case .coreDataError:
            return "Try restarting the app or re-syncing your data"
        case .keychainError:
            return "Try logging out and logging back in"
        case .syncConflict:
            return "Your local changes have been overwritten by remote data"
        case .rateLimitExceeded:
            return "Wait a moment before making more requests"
        case .invalidResponse:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Error Presentation Helpers

extension KiroError {
    /// Creates an alert configuration for presenting this error in SwiftUI
    var alertConfiguration: AlertConfiguration {
        AlertConfiguration(
            title: "Error",
            message: errorDescription ?? "An unknown error occurred",
            primaryButton: .default(Text("OK"))
        )
    }
    
    /// Creates an alert configuration with a retry action
    func alertConfiguration(retryAction: @escaping () -> Void) -> AlertConfiguration {
        AlertConfiguration(
            title: failureReason ?? "Error",
            message: errorDescription ?? "An unknown error occurred",
            primaryButton: .default(Text("Retry"), action: retryAction),
            secondaryButton: .cancel()
        )
    }
}

/// Configuration for SwiftUI alerts
struct AlertConfiguration {
    let title: String
    let message: String
    let primaryButton: Alert.Button
    var secondaryButton: Alert.Button?
    
    /// Creates a SwiftUI Alert from this configuration
    func makeAlert() -> Alert {
        if let secondaryButton = secondaryButton {
            return Alert(
                title: Text(title),
                message: Text(message),
                primaryButton: primaryButton,
                secondaryButton: secondaryButton
            )
        } else {
            return Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: primaryButton
            )
        }
    }
}

// MARK: - View Modifier for Error Handling

struct ErrorAlert: ViewModifier {
    @Binding var error: KiroError?
    var retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(item: Binding(
                get: { error.map { ErrorWrapper(error: $0) } },
                set: { error = $0?.error }
            )) { wrapper in
                if let retryAction = retryAction {
                    return wrapper.error.alertConfiguration(retryAction: retryAction).makeAlert()
                } else {
                    return wrapper.error.alertConfiguration.makeAlert()
                }
            }
    }
}

/// Wrapper to make KiroError identifiable for SwiftUI alerts
struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: KiroError
}

extension View {
    /// Presents an alert when a KiroError occurs
    func errorAlert(_ error: Binding<KiroError?>, retryAction: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(error: error, retryAction: retryAction))
    }
}
