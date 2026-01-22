import Foundation

/// Service for making requests to the OpenAI API
actor OpenAIService {
    static let shared = OpenAIService()

    private let baseURL = URL(string: "https://api.openai.com/v1")!
    private let logger = LoggingService.shared

    private init() {}

    // MARK: - Request/Response Types

    struct ChatCompletionRequest: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double?
        let maxTokens: Int?

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature
            case maxTokens = "max_tokens"
        }

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct ChatCompletionResponse: Decodable {
        let id: String
        let choices: [Choice]
        let usage: Usage?

        struct Choice: Decodable {
            let index: Int
            let message: Message
            let finishReason: String?

            enum CodingKeys: String, CodingKey {
                case index, message
                case finishReason = "finish_reason"
            }

            struct Message: Decodable {
                let role: String
                let content: String?
            }
        }

        struct Usage: Decodable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
            }
        }
    }

    struct ErrorResponse: Decodable {
        let error: ErrorDetail

        struct ErrorDetail: Decodable {
            let message: String
            let type: String?
            let code: String?
        }
    }

    // MARK: - Errors

    enum OpenAIError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case httpError(Int, String)
        case decodingError(Error)
        case networkError(Error)
        case rateLimited
        case invalidAPIKey
        case insufficientQuota

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenAI API key not configured. Please add your API key in Settings."
            case .invalidResponse:
                return "Invalid response from OpenAI API"
            case .httpError(let code, let message):
                return "OpenAI API error (\(code)): \(message)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .rateLimited:
                return "Rate limited. Please wait a moment and try again."
            case .invalidAPIKey:
                return "Invalid OpenAI API key. Please check your API key in Settings."
            case .insufficientQuota:
                return "OpenAI API quota exceeded. Please check your billing."
            }
        }
    }

    // MARK: - Public Methods

    /// Generates text using OpenAI's chat completion API
    @MainActor
    func generateText(
        prompt: String,
        systemPrompt: String? = nil,
        model: OpenAIModel = .gpt4o,
        temperature: Double = 0.7,
        maxTokens: Int? = nil
    ) async throws -> String {
        guard let apiKey = AISettingsManager.shared.getOpenAIKey(), !apiKey.isEmpty else {
            throw OpenAIError.noAPIKey
        }

        var messages: [ChatCompletionRequest.Message] = []

        if let systemPrompt = systemPrompt {
            messages.append(.init(role: "system", content: systemPrompt))
        }

        messages.append(.init(role: "user", content: prompt))

        let request = ChatCompletionRequest(
            model: model.rawValue,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens
        )

        return try await performRequest(request, apiKey: apiKey)
    }

    /// Tests the API connection with a simple request
    @MainActor
    func testConnection() async throws -> Bool {
        guard let apiKey = AISettingsManager.shared.getOpenAIKey(), !apiKey.isEmpty else {
            throw OpenAIError.noAPIKey
        }

        let request = ChatCompletionRequest(
            model: OpenAIModel.gpt4oMini.rawValue,
            messages: [.init(role: "user", content: "Hi")],
            temperature: 0,
            maxTokens: 5
        )

        _ = try await performRequest(request, apiKey: apiKey)
        return true
    }

    // MARK: - Private Methods

    private func performRequest(_ request: ChatCompletionRequest, apiKey: String) async throws -> String {
        let url = baseURL.appendingPathComponent("chat/completions")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw OpenAIError.networkError(error)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }

            // Handle specific error codes
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw OpenAIError.invalidAPIKey
            case 429:
                throw OpenAIError.rateLimited
            case 402, 403:
                // Check if it's a quota issue
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                   errorResponse.error.code == "insufficient_quota" {
                    throw OpenAIError.insufficientQuota
                }
                throw OpenAIError.httpError(httpResponse.statusCode, extractErrorMessage(from: data))
            default:
                throw OpenAIError.httpError(httpResponse.statusCode, extractErrorMessage(from: data))
            }

            do {
                let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                guard let content = completionResponse.choices.first?.message.content else {
                    throw OpenAIError.invalidResponse
                }
                return content
            } catch let error as OpenAIError {
                throw error
            } catch {
                throw OpenAIError.decodingError(error)
            }
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError(error)
        }
    }

    private func extractErrorMessage(from data: Data) -> String {
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.error.message
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}
