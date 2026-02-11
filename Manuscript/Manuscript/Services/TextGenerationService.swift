import Foundation
import AnyLanguageModel

/// Error type for text generation service
enum TextGenerationError: LocalizedError {
    case noAPIKey(AIModelProvider)
    case generationFailed(String)
    case foundationModelsUnavailable

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let provider):
            return "No API key configured for \(provider.displayName). Please add your API key in Settings."
        case .generationFailed(let message):
            return "Text generation failed: \(message)"
        case .foundationModelsUnavailable:
            return "Apple Intelligence is not available on this device. Please update to iOS 26 or macOS 26, or configure a cloud AI provider in Settings."
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

        case .apple:
            if #available(iOS 26, macOS 26, *) {
                let languageModel = SystemLanguageModel.default
                return try await generate(with: languageModel, prompt: prompt, systemPrompt: systemPrompt)
            } else {
                throw TextGenerationError.foundationModelsUnavailable
            }
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

        case .apple:
            if #available(iOS 26, macOS 26, *) {
                let languageModel = SystemLanguageModel.default
                _ = try await generate(with: languageModel, prompt: "Hi", systemPrompt: nil)
                return true
            } else {
                throw TextGenerationError.foundationModelsUnavailable
            }
        }
    }

    // MARK: - Private

    private nonisolated func generate(
        with model: any LanguageModel,
        prompt: String,
        systemPrompt: String?
    ) async throws -> String {
        let session: LanguageModelSession
        if let systemPrompt, !systemPrompt.isEmpty {
            session = LanguageModelSession(model: model, instructions: systemPrompt)
        } else {
            session = LanguageModelSession(model: model)
        }

        let response = try await session.respond(to: prompt)
        return response.content
    }
}
