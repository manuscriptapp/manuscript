import Foundation
import SwiftUI
import Combine

/// Represents an app error that can be displayed to the user
struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let underlyingError: Error?
    let timestamp: Date

    init(title: String, message: String, underlyingError: Error? = nil) {
        self.title = title
        self.message = message
        self.underlyingError = underlyingError
        self.timestamp = Date()
    }

    /// Creates an AppError from a document loading error
    static func documentLoadError(_ error: Error, filename: String? = nil) -> AppError {
        let title = "Failed to Open Document"
        var message: String

        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                message = "The document is missing required data: '\(key.stringValue)'."
                if !context.codingPath.isEmpty {
                    let path = context.codingPath.map { $0.stringValue }.joined(separator: " → ")
                    message += "\n\nLocation: \(path)"
                }
                message += "\n\nThis may be an older document format. Try opening it in an earlier version of Manuscript and re-saving it."
            case .typeMismatch(let type, let context):
                message = "The document contains invalid data (expected \(type))."
                if !context.codingPath.isEmpty {
                    let path = context.codingPath.map { $0.stringValue }.joined(separator: " → ")
                    message += "\n\nLocation: \(path)"
                }
            case .valueNotFound(let type, let context):
                message = "The document is missing a required value (expected \(type))."
                if !context.codingPath.isEmpty {
                    let path = context.codingPath.map { $0.stringValue }.joined(separator: " → ")
                    message += "\n\nLocation: \(path)"
                }
            case .dataCorrupted(let context):
                message = "The document data is corrupted: \(context.debugDescription)"
            @unknown default:
                message = "Failed to read the document: \(error.localizedDescription)"
            }
        } else if let cocoaError = error as? CocoaError {
            switch cocoaError.code {
            case .fileReadCorruptFile:
                message = "The document appears to be corrupted or is not a valid Manuscript document."
            case .fileReadNoSuchFile:
                message = "The document could not be found. It may have been moved or deleted."
            case .fileReadNoPermission:
                message = "You don't have permission to open this document."
            case .fileReadUnsupportedScheme:
                message = "This file format is not supported."
            default:
                message = error.localizedDescription
            }
        } else {
            message = error.localizedDescription
        }

        if let filename = filename {
            message = "Could not open \"\(filename)\".\n\n\(message)"
        }

        return AppError(title: title, message: message, underlyingError: error)
    }

    /// Creates an AppError from a document save error
    static func documentSaveError(_ error: Error, filename: String? = nil) -> AppError {
        let title = "Failed to Save Document"
        var message = error.localizedDescription

        if let filename = filename {
            message = "Could not save \"\(filename)\".\n\n\(message)"
        }

        return AppError(title: title, message: message, underlyingError: error)
    }
}

/// Global error manager for displaying errors to the user
@MainActor
class ErrorManager: ObservableObject {
    static let shared = ErrorManager()

    /// The current error to display (nil if no error)
    @Published var currentError: AppError?

    /// History of recent errors (for debugging)
    @Published private(set) var errorHistory: [AppError] = []

    private let maxHistoryCount = 10

    private init() {}

    /// Show an error to the user
    func showError(_ error: AppError) {
        print("🚨 [ErrorManager] Showing error: \(error.title) - \(error.message)")
        currentError = error

        // Add to history
        errorHistory.insert(error, at: 0)
        if errorHistory.count > maxHistoryCount {
            errorHistory.removeLast()
        }
    }

    /// Show a document load error
    func showDocumentLoadError(_ error: Error, filename: String? = nil) {
        showError(.documentLoadError(error, filename: filename))
    }

    /// Show a document save error
    func showDocumentSaveError(_ error: Error, filename: String? = nil) {
        showError(.documentSaveError(error, filename: filename))
    }

    /// Show a generic error
    func showGenericError(title: String, message: String, error: Error? = nil) {
        showError(AppError(title: title, message: message, underlyingError: error))
    }

    /// Dismiss the current error
    func dismissError() {
        currentError = nil
    }

    /// Clear error history
    func clearHistory() {
        errorHistory.removeAll()
    }
}

// MARK: - SwiftUI View Modifier for Error Alerts

struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorManager: ErrorManager

    func body(content: Content) -> some View {
        content
            .alert(
                errorManager.currentError?.title ?? "Error",
                isPresented: Binding(
                    get: { errorManager.currentError != nil },
                    set: { if !$0 { errorManager.dismissError() } }
                ),
                presenting: errorManager.currentError
            ) { _ in
                Button("OK", role: .cancel) {
                    errorManager.dismissError()
                }
            } message: { error in
                Text(error.message)
            }
    }
}

extension View {
    /// Adds an alert that displays errors from the shared ErrorManager
    func withErrorAlert() -> some View {
        modifier(ErrorAlertModifier(errorManager: ErrorManager.shared))
    }
}
