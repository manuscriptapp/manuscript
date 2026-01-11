import Foundation
import OSLog

class LoggingService {
    static let shared = LoggingService()
    private let logger: Logger
    
    private init() {
        self.logger = Logger(subsystem: "com.dahlsjoo.manuscript", category: "api")
    }
    
    func logAPIError(_ error: Error, endpoint: String, context: [String: Any] = [:]) {
        var contextDescription = context.isEmpty ? "" : " Context: \(context)"
        
        switch error {
        case let apiError as APIError:
            switch apiError {
            case .invalidResponse:
                logger.error("🔴 Invalid API response from endpoint: \(endpoint)\(contextDescription)")
            case .httpError(let statusCode, let errorMessage):
                let messageInfo = errorMessage.map { " - Message: \($0)" } ?? ""
                logger.error("🔴 HTTP error \(statusCode) from endpoint: \(endpoint)\(messageInfo)\(contextDescription)")
            case .decodingError(let decodingError):
                logger.error("🔴 Failed to decode response from endpoint: \(endpoint). Error: \(decodingError.localizedDescription)\(contextDescription)")
            case .networkError(let networkError):
                logger.error("🔴 Network error from endpoint: \(endpoint). Error: \(networkError.localizedDescription)\(contextDescription)")
            }
        default:
            logger.error("🔴 Unexpected error from endpoint: \(endpoint). Error: \(error.localizedDescription)\(contextDescription)")
        }
    }
    
    func logAPIRequest(endpoint: String, context: [String: Any] = [:]) {
        var contextDescription = context.isEmpty ? "" : " Context: \(context)"
        logger.debug("📤 API request to endpoint: \(endpoint)\(contextDescription)")
    }
    
    func logAPIResponse(endpoint: String, context: [String: Any] = [:]) {
        var contextDescription = context.isEmpty ? "" : " Context: \(context)"
        logger.debug("📥 API response from endpoint: \(endpoint)\(contextDescription)")
    }
} 