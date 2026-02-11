import Foundation

/// Service for making requests to a local Ollama instance.
/// Ollama runs models locally and exposes an OpenAI-compatible API.
/// Default endpoint: http://localhost:11434
actor OllamaService: AnyModelProvider {
    static let shared = OllamaService()

    private let logger = LoggingService.shared

    private init() {}

    // MARK: - Configuration

    /// The base URL for the Ollama API. Defaults to localhost:11434.
    @MainActor
    var baseURL: URL {
        let endpoint = AISettingsManager.shared.ollamaEndpoint
        return URL(string: endpoint) ?? URL(string: "http://localhost:11434")!
    }

    // MARK: - Request/Response Types (OpenAI-compatible)

    private struct ChatCompletionRequest: Encodable {
        let model: String
        let messages: [Message]
        let options: Options?
        let stream: Bool

        struct Message: Encodable {
            let role: String
            let content: String
        }

        struct Options: Encodable {
            let temperature: Double?
            let numPredict: Int?

            enum CodingKeys: String, CodingKey {
                case temperature
                case numPredict = "num_predict"
            }
        }
    }

    private struct ChatCompletionResponse: Decodable {
        let model: String?
        let message: MessageContent?
        let done: Bool?
        let error: String?

        struct MessageContent: Decodable {
            let role: String
            let content: String
        }
    }

    private struct TagsResponse: Decodable {
        let models: [ModelInfo]?

        struct ModelInfo: Decodable {
            let name: String
            let size: Int64?
            let modifiedAt: String?

            enum CodingKeys: String, CodingKey {
                case name, size
                case modifiedAt = "modified_at"
            }
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
        let url = await baseURL

        var messages: [ChatCompletionRequest.Message] = []
        if let systemPrompt {
            messages.append(.init(role: "system", content: systemPrompt))
        }
        messages.append(.init(role: "user", content: prompt))

        let request = ChatCompletionRequest(
            model: modelId,
            messages: messages,
            options: .init(temperature: temperature, numPredict: maxTokens),
            stream: false
        )

        return try await performRequest(request, baseURL: url)
    }

    func testConnection() async throws -> Bool {
        let url = await baseURL
        let pingURL = url.appendingPathComponent("api/tags")

        var urlRequest = URLRequest(url: pingURL)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AnyModelError.ollamaNotRunning
            }
            return true
        } catch let error as AnyModelError {
            throw error
        } catch {
            throw AnyModelError.ollamaNotRunning
        }
    }

    // MARK: - Local Model Discovery

    /// Fetches the list of locally available models from Ollama
    func fetchLocalModels() async throws -> [String] {
        let url = await baseURL
        let tagsURL = url.appendingPathComponent("api/tags")

        var urlRequest = URLRequest(url: tagsURL)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 5

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AnyModelError.ollamaNotRunning
            }

            let tagsResponse = try JSONDecoder().decode(TagsResponse.self, from: data)
            return tagsResponse.models?.map { $0.name } ?? []
        } catch let error as AnyModelError {
            throw error
        } catch {
            throw AnyModelError.ollamaNotRunning
        }
    }

    // MARK: - Private

    private func performRequest(_ request: ChatCompletionRequest, baseURL: URL) async throws -> String {
        let url = baseURL.appendingPathComponent("api/chat")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 120 // Local models can be slow

        urlRequest.httpBody = try JSONEncoder().encode(request)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnyModelError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 404:
                throw AnyModelError.localModelUnavailable(request.model)
            default:
                throw AnyModelError.httpError(httpResponse.statusCode, extractErrorMessage(from: data))
            }

            let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

            if let error = chatResponse.error {
                if error.lowercased().contains("not found") {
                    throw AnyModelError.localModelUnavailable(request.model)
                }
                throw AnyModelError.httpError(0, error)
            }

            guard let content = chatResponse.message?.content, !content.isEmpty else {
                throw AnyModelError.invalidResponse
            }

            return content
        } catch let error as AnyModelError {
            throw error
        } catch let urlError as URLError where urlError.code == .cannotConnectToHost || urlError.code == .networkConnectionLost {
            throw AnyModelError.ollamaNotRunning
        } catch let error as DecodingError {
            throw AnyModelError.decodingError(error)
        } catch {
            throw AnyModelError.networkError(error)
        }
    }

    private func extractErrorMessage(from data: Data) -> String {
        if let response = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
           let error = response.error {
            return error
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}
