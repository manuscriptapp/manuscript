import Foundation

/// Service for making requests to the Google Gemini API
actor GeminiService: AnyModelProvider {
    static let shared = GeminiService()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let logger = LoggingService.shared

    private init() {}

    // MARK: - Request/Response Types

    struct GenerateContentRequest: Encodable {
        let contents: [Content]
        let systemInstruction: SystemInstruction?
        let generationConfig: GenerationConfig?

        struct Content: Encodable {
            let role: String
            let parts: [Part]
        }

        struct Part: Encodable {
            let text: String
        }

        struct SystemInstruction: Encodable {
            let parts: [Part]
        }

        struct GenerationConfig: Encodable {
            let temperature: Double?
            let maxOutputTokens: Int?
        }
    }

    struct GenerateContentResponse: Decodable {
        let candidates: [Candidate]?
        let usageMetadata: UsageMetadata?
        let error: ErrorDetail?

        struct Candidate: Decodable {
            let content: Content?
            let finishReason: String?
        }

        struct Content: Decodable {
            let parts: [Part]?
            let role: String?
        }

        struct Part: Decodable {
            let text: String?
        }

        struct UsageMetadata: Decodable {
            let promptTokenCount: Int?
            let candidatesTokenCount: Int?
            let totalTokenCount: Int?
        }

        struct ErrorDetail: Decodable {
            let code: Int?
            let message: String?
            let status: String?
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

        let contents = [
            GenerateContentRequest.Content(
                role: "user",
                parts: [.init(text: prompt)]
            )
        ]

        let systemInstruction: GenerateContentRequest.SystemInstruction?
        if let systemPrompt {
            systemInstruction = .init(parts: [.init(text: systemPrompt)])
        } else {
            systemInstruction = nil
        }

        let config = GenerateContentRequest.GenerationConfig(
            temperature: temperature,
            maxOutputTokens: maxTokens
        )

        let request = GenerateContentRequest(
            contents: contents,
            systemInstruction: systemInstruction,
            generationConfig: config
        )

        return try await performRequest(request, modelId: modelId, apiKey: apiKey)
    }

    func testConnection() async throws -> Bool {
        let apiKey = try await getAPIKey()

        let request = GenerateContentRequest(
            contents: [.init(role: "user", parts: [.init(text: "Hi")])],
            systemInstruction: nil,
            generationConfig: .init(temperature: 0, maxOutputTokens: 10)
        )

        _ = try await performRequest(request, modelId: "gemini-2.0-flash-lite", apiKey: apiKey)
        return true
    }

    // MARK: - Private

    @MainActor
    private func getAPIKey() throws -> String {
        guard let apiKey = AISettingsManager.shared.getGeminiKey(), !apiKey.isEmpty else {
            throw AnyModelError.noAPIKey(.gemini)
        }
        return apiKey
    }

    private func performRequest(
        _ request: GenerateContentRequest,
        modelId: String,
        apiKey: String
    ) async throws -> String {
        let urlString = "\(baseURL)/models/\(modelId):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AnyModelError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        urlRequest.httpBody = try JSONEncoder().encode(request)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnyModelError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 400:
                let message = extractErrorMessage(from: data)
                if message.lowercased().contains("api key") {
                    throw AnyModelError.invalidAPIKey(.gemini)
                }
                throw AnyModelError.httpError(400, message)
            case 401, 403:
                throw AnyModelError.invalidAPIKey(.gemini)
            case 429:
                throw AnyModelError.rateLimited
            case 503:
                throw AnyModelError.overloaded
            default:
                throw AnyModelError.httpError(httpResponse.statusCode, extractErrorMessage(from: data))
            }

            let decoder = JSONDecoder()
            let contentResponse = try decoder.decode(GenerateContentResponse.self, from: data)

            if let error = contentResponse.error {
                throw AnyModelError.httpError(error.code ?? 0, error.message ?? "Unknown error")
            }

            guard let text = contentResponse.candidates?.first?.content?.parts?.compactMap({ $0.text }).joined(),
                  !text.isEmpty else {
                throw AnyModelError.invalidResponse
            }

            return text
        } catch let error as AnyModelError {
            throw error
        } catch let error as DecodingError {
            throw AnyModelError.decodingError(error)
        } catch {
            throw AnyModelError.networkError(error)
        }
    }

    private func extractErrorMessage(from data: Data) -> String {
        if let response = try? JSONDecoder().decode(GenerateContentResponse.self, from: data),
           let message = response.error?.message {
            return message
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}
