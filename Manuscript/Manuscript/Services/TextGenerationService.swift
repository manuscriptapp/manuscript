import Foundation

/// Error type for text generation service
enum TextGenerationError: LocalizedError {
    case noAPIKey(AIModelProvider)

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let provider):
            return "No API key configured for \(provider.displayName). Please add your API key in Settings."
        }
    }
}

/// Unified text generation service that routes requests through the AnyModel system.
/// Supports OpenAI, Anthropic, Gemini, Grok, DeepSeek, and local (Ollama) models.
/// When no API keys are configured, automatically falls back to local models.
actor TextGenerationService {
    static let shared = TextGenerationService()

    private init() {}

    /// Generates text using the currently configured AI provider and model.
    /// Routes to the appropriate service based on AISettingsManager's selected provider.
    @MainActor
    func generateText(prompt: String, systemPrompt: String? = nil) async throws -> String {
        let settings = AISettingsManager.shared
        let provider = settings.selectedProviderKind
        let modelId = settings.selectedModel.id
        let temperature = 0.7
        let maxTokens = 4096

        // If the selected provider needs an API key and doesn't have one,
        // fall back to local models
        if provider.requiresAPIKey && !settings.hasAPIKeyForSelectedProvider {
            return try await OllamaService.shared.generateText(
                prompt: prompt,
                systemPrompt: systemPrompt,
                modelId: AnyModelRegistry.defaultModel(for: .local).id,
                temperature: temperature,
                maxTokens: maxTokens
            )
        }

        switch provider {
        case .local:
            // Use custom model name if set, otherwise use selected model
            let localModelId: String
            if !settings.ollamaCustomModel.isEmpty {
                localModelId = settings.ollamaCustomModel
            } else {
                localModelId = modelId
            }
            return try await OllamaService.shared.generateText(
                prompt: prompt,
                systemPrompt: systemPrompt,
                modelId: localModelId,
                temperature: temperature,
                maxTokens: maxTokens
            )

        case .openAI:
            return try await OpenAIService.shared.generateText(
                prompt: prompt,
                systemPrompt: systemPrompt,
                model: settings.selectedOpenAIModel
            )

        case .anthropic:
            return try await ClaudeAPIService.shared.generateText(
                prompt: prompt,
                systemPrompt: systemPrompt,
                model: settings.selectedClaudeModel
            )

        case .gemini:
            return try await GeminiService.shared.generateText(
                prompt: prompt,
                systemPrompt: systemPrompt,
                modelId: modelId,
                temperature: temperature,
                maxTokens: maxTokens
            )

        case .grok:
            return try await GrokService.shared.generateText(
                prompt: prompt,
                systemPrompt: systemPrompt,
                modelId: modelId,
                temperature: temperature,
                maxTokens: maxTokens
            )

        case .deepSeek:
            return try await DeepSeekService.shared.generateText(
                prompt: prompt,
                systemPrompt: systemPrompt,
                modelId: modelId,
                temperature: temperature,
                maxTokens: maxTokens
            )
        }
    }

    /// Test the connection for a specific provider
    @MainActor
    func testConnection(for provider: ModelProviderKind) async throws -> Bool {
        switch provider {
        case .local:
            return try await OllamaService.shared.testConnection()
        case .openAI:
            return try await OpenAIService.shared.testConnection()
        case .anthropic:
            return try await ClaudeAPIService.shared.testConnection()
        case .gemini:
            return try await GeminiService.shared.testConnection()
        case .grok:
            return try await GrokService.shared.testConnection()
        case .deepSeek:
            return try await DeepSeekService.shared.testConnection()
        }
    }
}
