import Foundation
import OSLog

// MARK: - Production Logging Infrastructure

/// Centralized logging using Apple's unified logging system (OSLog).
/// Provides category-based loggers for different subsystems of the app.
///
/// Usage:
/// ```swift
/// Log.document.info("Document loaded: \(title)")
/// Log.api.error("Request failed: \(error.localizedDescription)")
/// Log.app.debug("Debug info: \(value, privacy: .private)")
/// ```
///
/// Log Levels:
/// - `.debug`: Development only, not persisted
/// - `.info`: General flow, memory only
/// - `.notice`: Important state changes, persisted (default)
/// - `.error`: Recoverable errors, persisted
/// - `.fault`: Critical bugs/crashes, persisted + highlighted
enum Log {
    /// Bundle identifier used as the logging subsystem
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.manuscript.app"

    // MARK: - Category Loggers

    /// General app lifecycle, startup, and configuration
    static let app = Logger(subsystem: subsystem, category: "app")

    /// Document operations: loading, saving, syncing
    static let document = Logger(subsystem: subsystem, category: "document")

    /// External API requests and responses
    static let api = Logger(subsystem: subsystem, category: "api")

    /// iCloud and sync operations
    static let sync = Logger(subsystem: subsystem, category: "sync")

    /// UI events and view lifecycle
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Import/export operations (Scrivener, compile, etc.)
    static let io = Logger(subsystem: subsystem, category: "io")

    /// AI services (Claude, OpenAI, text generation)
    static let ai = Logger(subsystem: subsystem, category: "ai")

    /// Audio playback and text-to-speech
    static let audio = Logger(subsystem: subsystem, category: "audio")
}

// MARK: - Legacy LoggingService (Deprecated)

/// Legacy logging service for backward compatibility.
/// New code should use `Log` directly.
@available(*, deprecated, message: "Use Log.api instead")
class LoggingService {
    static let shared = LoggingService()

    private init() {}

    func logAPIError(_ error: Error, endpoint: String, context: [String: Any] = [:]) {
        let contextDescription = context.isEmpty ? "" : " Context: \(context)"

        switch error {
        case let apiError as APIError:
            switch apiError {
            case .invalidResponse:
                Log.api.error("Invalid API response from endpoint: \(endpoint)\(contextDescription)")
            case .httpError(let statusCode, let errorMessage):
                let messageInfo = errorMessage.map { " - Message: \($0)" } ?? ""
                Log.api.error("HTTP error \(statusCode) from endpoint: \(endpoint)\(messageInfo)\(contextDescription)")
            case .decodingError(let decodingError):
                Log.api.error("Failed to decode response from endpoint: \(endpoint). Error: \(decodingError.localizedDescription)\(contextDescription)")
            case .networkError(let networkError):
                Log.api.error("Network error from endpoint: \(endpoint). Error: \(networkError.localizedDescription)\(contextDescription)")
            }
        default:
            Log.api.error("Unexpected error from endpoint: \(endpoint). Error: \(error.localizedDescription)\(contextDescription)")
        }
    }

    func logAPIRequest(endpoint: String, context: [String: Any] = [:]) {
        let contextDescription = context.isEmpty ? "" : " Context: \(context)"
        Log.api.debug("API request to endpoint: \(endpoint)\(contextDescription)")
    }

    func logAPIResponse(endpoint: String, context: [String: Any] = [:]) {
        let contextDescription = context.isEmpty ? "" : " Context: \(context)"
        Log.api.debug("API response from endpoint: \(endpoint)\(contextDescription)")
    }
}
