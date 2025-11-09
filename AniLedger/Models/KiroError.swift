//
//  KiroError.swift
//  AniLedger
//
//  Created by Niraj Dilshan on 10/13/2025.
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
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case invalidResponse
    case timeout
    case noInternetConnection
    case serverUnavailable
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .networkError(let error):
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    return "No internet connection available"
                case NSURLErrorTimedOut:
                    return "Request timed out"
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    return "Cannot connect to AniList servers"
                default:
                    return "Network error: \(error.localizedDescription)"
                }
            }
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message, let code):
            if let code = code {
                switch code {
                case 400:
                    return "Invalid request. Please try again."
                case 401:
                    return "Authentication required. Please log in again."
                case 403:
                    return "Access denied. Check your permissions."
                case 404:
                    return "The requested content was not found."
                case 500...599:
                    return "AniList servers are experiencing issues. Please try again later."
                default:
                    return "API error (\(code)): \(message)"
                }
            }
            return "API error: \(message)"
        case .decodingError:
            return "Unable to process server response. The app may need an update."
        case .coreDataError:
            return "A database error occurred. Your data is safe."
        case .keychainError:
            return "Unable to access secure storage."
        case .syncConflict:
            return "Sync conflict detected. Remote changes will be applied."
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                let minutes = Int(ceil(retryAfter / 60))
                return "Too many requests. Please wait \(minutes) minute\(minutes == 1 ? "" : "s") before trying again."
            }
            return "Too many requests. Please wait a moment before trying again."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .timeout:
            return "Request timed out. Please check your connection and try again."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .serverUnavailable:
            return "AniList servers are currently unavailable. Please try again later."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .authenticationFailed:
            return "Unable to authenticate with AniList"
        case .networkError:
            return "Network connection issue"
        case .apiError(_, let code):
            if let code = code, code >= 500 {
                return "AniList server error"
            }
            return "AniList API error"
        case .decodingError:
            return "Data format error"
        case .coreDataError:
            return "Local database error"
        case .keychainError:
            return "Secure storage error"
        case .syncConflict:
            return "Data conflict between local and remote"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .invalidResponse:
            return "Invalid server response"
        case .timeout:
            return "Connection timeout"
        case .noInternetConnection:
            return "No internet connection"
        case .serverUnavailable:
            return "Server unavailable"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Please try logging in again. If the problem persists, check your AniList account status."
        case .networkError(let error):
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet:
                    return "Connect to Wi-Fi or cellular data and try again."
                case NSURLErrorTimedOut:
                    return "Check your internet connection and try again."
                default:
                    return "Check your internet connection and try again."
                }
            }
            return "Check your internet connection and try again."
        case .apiError(_, let code):
            if let code = code {
                switch code {
                case 401:
                    return "Please log out and log back in to refresh your session."
                case 500...599:
                    return "AniList is experiencing technical difficulties. Please try again in a few minutes."
                default:
                    return "Please try again. If the problem persists, contact support."
                }
            }
            return "Please try again later."
        case .decodingError:
            return "Please check for app updates. If you're on the latest version, contact support."
        case .coreDataError:
            return "Try restarting the app. If the issue persists, you may need to re-sync your data."
        case .keychainError:
            return "Try logging out and logging back in. You may need to grant keychain access."
        case .syncConflict:
            return "Your local changes have been overwritten by remote data. This is normal when syncing."
        case .rateLimitExceeded:
            return "Wait a few minutes before making more requests. AniList limits how often you can access their API."
        case .invalidResponse:
            return "Please try again. If the problem persists, AniList may be experiencing issues."
        case .timeout:
            return "Check your internet connection speed and try again."
        case .noInternetConnection:
            return "Connect to Wi-Fi or cellular data to use online features."
        case .serverUnavailable:
            return "AniList servers are temporarily unavailable. Please try again in a few minutes."
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

// MARK: - Error Helpers

extension KiroError {
    /// Returns true if this error is recoverable with a retry
    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .serverUnavailable, .rateLimitExceeded, .invalidResponse:
            return true
        case .apiError(_, let code):
            // Retry on server errors (5xx) but not client errors (4xx)
            if let code = code {
                return code >= 500
            }
            return false
        default:
            return false
        }
    }
    
    /// Returns true if this error requires re-authentication
    var requiresReauth: Bool {
        switch self {
        case .authenticationFailed:
            return true
        case .apiError(_, let code):
            return code == 401
        default:
            return false
        }
    }
    
    /// Returns a user-friendly title for the error
    var userFriendlyTitle: String {
        switch self {
        case .noInternetConnection:
            return "No Internet Connection"
        case .timeout:
            return "Connection Timeout"
        case .serverUnavailable:
            return "Service Unavailable"
        case .rateLimitExceeded:
            return "Too Many Requests"
        case .authenticationFailed:
            return "Authentication Required"
        case .apiError(_, let code):
            if let code = code, code >= 500 {
                return "Server Error"
            }
            return "Request Failed"
        default:
            return "Error"
        }
    }
    
    /// Returns true if this error should be shown as a toast instead of a full error view
    var shouldShowAsToast: Bool {
        switch self {
        case .syncConflict, .coreDataError:
            return true
        case .rateLimitExceeded:
            return true
        default:
            return false
        }
    }
    
    /// Converts the error to a brief toast message
    var toastMessage: String {
        switch self {
        case .syncConflict:
            return "Sync conflict resolved"
        case .rateLimitExceeded:
            return "Too many requests. Please wait."
        case .coreDataError:
            return "Database error occurred"
        default:
            return errorDescription ?? "An error occurred"
        }
    }
}
