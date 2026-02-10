import Foundation

/// Service for making requests to the Anthropic Claude API
actor ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let baseURL = URL(string: "https://api.anthropic.com/v1")!
    private let apiVersion = "2023-06-01"
    private let logger = LoggingService.shared

    private init() {}

    // MARK: - Request/Response Types

    struct MessagesRequest: Encodable {
        let model: String
        let messages: [Message]
        let maxTokens: Int
        let system: String?
        let temperature: Double?

        enum CodingKeys: String, CodingKey {
            case model, messages, system, temperature
            case maxTokens = "max_tokens"
        }

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct MessagesResponse: Decodable {
        let id: String
        let type: String
        let role: String
        let content: [ContentBlock]
        let stopReason: String?
        let usage: Usage

        enum CodingKeys: String, CodingKey {
            case id, type, role, content, usage
            case stopReason = "stop_reason"
        }

        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }

        struct Usage: Decodable {
            let inputTokens: Int
            let outputTokens: Int

            enum CodingKeys: String, CodingKey {
                case inputTokens = "input_tokens"
                case outputTokens = "output_tokens"
            }
        }
    }

    struct ErrorResponse: Decodable {
        let type: String
        let error: ErrorDetail

        struct ErrorDetail: Decodable {
            let type: String
            let message: String
        }
    }

    // MARK: - Errors

    enum ClaudeError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case httpError(Int, String)
        case decodingError(Error)
        case networkError(Error)
        case rateLimited
        case invalidAPIKey
        case overloaded

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Claude API key not configured. Please add your API key in Settings."
            case .invalidResponse:
                return "Invalid response from Claude API"
            case .httpError(let code, let message):
                return "Claude API error (\(code)): \(message)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .rateLimited:
                return "Rate limited. Please wait a moment and try again."
            case .invalidAPIKey:
                return "Invalid Claude API key. Please check your API key in Settings."
            case .overloaded:
                return "Claude API is currently overloaded. Please try again later."
            }
        }
    }

    // MARK: - Public Methods

    /// Generates text using Claude's messages API
    @MainActor
    func generateText(
        prompt: String,
        systemPrompt: String? = nil,
        model: ClaudeModel = .claude45Sonnet,
        temperature: Double = 0.7,
        maxTokens: Int = 4096
    ) async throws -> String {
        guard let apiKey = AISettingsManager.shared.getClaudeKey(), !apiKey.isEmpty else {
            throw ClaudeError.noAPIKey
        }

        let messages: [MessagesRequest.Message] = [
            .init(role: "user", content: prompt)
        ]

        let request = MessagesRequest(
            model: model.rawValue,
            messages: messages,
            maxTokens: maxTokens,
            system: systemPrompt,
            temperature: temperature
        )

        return try await performRequest(request, apiKey: apiKey)
    }

    /// Tests the API connection with a simple request
    @MainActor
    func testConnection() async throws -> Bool {
        guard let apiKey = AISettingsManager.shared.getClaudeKey(), !apiKey.isEmpty else {
            throw ClaudeError.noAPIKey
        }

        let request = MessagesRequest(
            model: ClaudeModel.claude35Haiku.rawValue,
            messages: [.init(role: "user", content: "Hi")],
            maxTokens: 10,
            system: nil,
            temperature: 0
        )

        _ = try await performRequest(request, apiKey: apiKey)
        return true
    }

    // MARK: - Private Methods

    private func performRequest(_ request: MessagesRequest, apiKey: String) async throws -> String {
        let url = baseURL.appendingPathComponent("messages")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw ClaudeError.networkError(error)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClaudeError.invalidResponse
            }

            // Handle specific error codes
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw ClaudeError.invalidAPIKey
            case 429:
                throw ClaudeError.rateLimited
            case 529:
                throw ClaudeError.overloaded
            default:
                throw ClaudeError.httpError(httpResponse.statusCode, extractErrorMessage(from: data))
            }

            do {
                let messagesResponse = try JSONDecoder().decode(MessagesResponse.self, from: data)
                // Extract text from content blocks
                let text = messagesResponse.content
                    .compactMap { $0.text }
                    .joined()

                if text.isEmpty {
                    throw ClaudeError.invalidResponse
                }
                return text
            } catch let error as ClaudeError {
                throw error
            } catch {
                throw ClaudeError.decodingError(error)
            }
        } catch let error as ClaudeError {
            throw error
        } catch {
            throw ClaudeError.networkError(error)
        }
    }

    private func extractErrorMessage(from data: Data) -> String {
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.error.message
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}
