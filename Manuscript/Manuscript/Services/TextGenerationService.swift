import Foundation
import AnyLanguageModel

/// Error type for text generation service
enum TextGenerationError: LocalizedError {
    case noAPIKey(AIModelProvider)
    case generationFailed(String)
    case ollamaUnavailable

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let provider):
            return "No API key configured for \(provider.displayName). Please add your API key in Settings."
        case .generationFailed(let message):
            return "Text generation failed: \(message)"
        case .ollamaUnavailable:
            return "Ollama is not running. Please start Ollama on your Mac and try again."
        }
    }
}

actor TextGenerationService {
    static let shared = TextGenerationService()

    private init() {}

    /// Generates text using the configured AI provider via AnyLanguageModel
    @MainActor
    func generateText(prompt: String, systemPrompt: String? = nil) async throws -> String {
        let settings = AISettingsManager.shared
        let provider = settings.selectedProvider
        let model = settings.selectedModel

        switch provider {
        case .openAI:
            guard let apiKey = settings.getAPIKey(for: .openAI), !apiKey.isEmpty else {
                throw TextGenerationError.noAPIKey(.openAI)
            }
            let languageModel = OpenAILanguageModel(apiKey: apiKey, model: model.id)
            return try await generate(with: languageModel, prompt: prompt, systemPrompt: systemPrompt)

        case .anthropic:
            guard let apiKey = settings.getAPIKey(for: .anthropic), !apiKey.isEmpty else {
                throw TextGenerationError.noAPIKey(.anthropic)
            }
            let languageModel = AnthropicLanguageModel(apiKey: apiKey, model: model.id)
            return try await generate(with: languageModel, prompt: prompt, systemPrompt: systemPrompt)

        case .gemini:
            guard let apiKey = settings.getAPIKey(for: .gemini), !apiKey.isEmpty else {
                throw TextGenerationError.noAPIKey(.gemini)
            }
            let languageModel = GeminiLanguageModel(apiKey: apiKey, model: model.id)
            return try await generate(with: languageModel, prompt: prompt, systemPrompt: systemPrompt)

        case .ollama:
            let host = settings.ollamaHost
            let baseURL = URL(string: host) ?? URL(string: "http://localhost:11434")!
            let languageModel = OllamaLanguageModel(baseURL: baseURL, model: model.id)
            return try await generate(with: languageModel, prompt: prompt, systemPrompt: systemPrompt)
        }
    }

    /// Tests the connection for a given provider
    @MainActor
    func testConnection(for provider: AIModelProvider) async throws -> Bool {
        let settings = AISettingsManager.shared
        let testModel: String

        switch provider {
        case .openAI:
            guard let apiKey = settings.getAPIKey(for: .openAI), !apiKey.isEmpty else {
                throw TextGenerationError.noAPIKey(.openAI)
            }
            testModel = "gpt-4o-mini"
            let languageModel = OpenAILanguageModel(apiKey: apiKey, model: testModel)
            _ = try await generate(with: languageModel, prompt: "Hi", systemPrompt: nil)
            return true

        case .anthropic:
            guard let apiKey = settings.getAPIKey(for: .anthropic), !apiKey.isEmpty else {
                throw TextGenerationError.noAPIKey(.anthropic)
            }
            testModel = "claude-3-5-haiku-20241022"
            let languageModel = AnthropicLanguageModel(apiKey: apiKey, model: testModel)
            _ = try await generate(with: languageModel, prompt: "Hi", systemPrompt: nil)
            return true

        case .gemini:
            guard let apiKey = settings.getAPIKey(for: .gemini), !apiKey.isEmpty else {
                throw TextGenerationError.noAPIKey(.gemini)
            }
            testModel = "gemini-2.0-flash"
            let languageModel = GeminiLanguageModel(apiKey: apiKey, model: testModel)
            _ = try await generate(with: languageModel, prompt: "Hi", systemPrompt: nil)
            return true

        case .ollama:
            let host = settings.ollamaHost
            let baseURL = URL(string: host) ?? URL(string: "http://localhost:11434")!
            let selectedModel = settings.selectedModel(for: .ollama)
            let languageModel = OllamaLanguageModel(baseURL: baseURL, model: selectedModel.id)
            _ = try await generate(with: languageModel, prompt: "Hi", systemPrompt: nil)
            return true
        }
    }

    // MARK: - Private

    private nonisolated func generate<M: LanguageModel>(
        with model: M,
        prompt: String,
        systemPrompt: String?
    ) async throws -> String {
        let session: LanguageModelSession<M>
        if let systemPrompt, !systemPrompt.isEmpty {
            session = LanguageModelSession(model: model, instructions: systemPrompt)
        } else {
            session = LanguageModelSession(model: model)
        }

        let response = try await session.respond(to: prompt)
        return response.content
    }
}
