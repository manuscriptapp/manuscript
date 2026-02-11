import Foundation

/// Service for making requests to the xAI Grok API.
/// Grok uses an OpenAI-compatible API format.
actor GrokService: AnyModelProvider {
    static let shared = GrokService()

    private let baseURL = URL(string: "https://api.x.ai/v1")!
    private let logger = LoggingService.shared

    private init() {}

    // MARK: - Request/Response Types (OpenAI-compatible)

    private struct ChatCompletionRequest: Encodable {
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

    private struct ChatCompletionResponse: Decodable {
        let id: String?
        let choices: [Choice]?
        let usage: Usage?
        let error: ErrorDetail?

        struct Choice: Decodable {
            let index: Int
            let message: MessageContent
            let finishReason: String?

            enum CodingKeys: String, CodingKey {
                case index, message
                case finishReason = "finish_reason"
            }

            struct MessageContent: Decodable {
                let role: String
                let content: String?
            }
        }

        struct Usage: Decodable {
            let promptTokens: Int?
            let completionTokens: Int?
            let totalTokens: Int?

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
            }
        }

        struct ErrorDetail: Decodable {
            let message: String?
            let type: String?
            let code: String?
        }
    }

    // MARK: - AnyModelProvider

    func generateText(
        prompt: String,
        systemPrompt: String?,
        modelId: String,
        temperature: Double,
        maxTokens: Int?
    ) async throws -> String {
        let apiKey = try await getAPIKey()

        var messages: [ChatCompletionRequest.Message] = []
        if let systemPrompt {
            messages.append(.init(role: "system", content: systemPrompt))
        }
        messages.append(.init(role: "user", content: prompt))

        let request = ChatCompletionRequest(
            model: modelId,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens
        )

        return try await performRequest(request, apiKey: apiKey)
    }

    func testConnection() async throws -> Bool {
        let apiKey = try await getAPIKey()

        let request = ChatCompletionRequest(
            model: "grok-3-mini-fast",
            messages: [.init(role: "user", content: "Hi")],
            temperature: 0,
            maxTokens: 5
        )

        _ = try await performRequest(request, apiKey: apiKey)
        return true
    }

    // MARK: - Private

    @MainActor
    private func getAPIKey() throws -> String {
        guard let apiKey = AISettingsManager.shared.getGrokKey(), !apiKey.isEmpty else {
            throw AnyModelError.noAPIKey(.grok)
        }
        return apiKey
    }

    private func performRequest(_ request: ChatCompletionRequest, apiKey: String) async throws -> String {
        let url = baseURL.appendingPathComponent("chat/completions")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        urlRequest.httpBody = try JSONEncoder().encode(request)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnyModelError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw AnyModelError.invalidAPIKey(.grok)
            case 429:
                throw AnyModelError.rateLimited
            case 503:
                throw AnyModelError.overloaded
            default:
                throw AnyModelError.httpError(httpResponse.statusCode, extractErrorMessage(from: data))
            }

            let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

            if let error = completionResponse.error {
                throw AnyModelError.httpError(0, error.message ?? "Unknown error")
            }

            guard let content = completionResponse.choices?.first?.message.content else {
                throw AnyModelError.invalidResponse
            }

            return content
        } catch let error as AnyModelError {
            throw error
        } catch let error as DecodingError {
            throw AnyModelError.decodingError(error)
        } catch {
            throw AnyModelError.networkError(error)
        }
    }

    private func extractErrorMessage(from data: Data) -> String {
        if let response = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
           let message = response.error?.message {
            return message
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}
