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

actor TextGenerationService {
    static let shared = TextGenerationService()

    private init() {}

    /// Generates text using the configured AI provider
    /// - Parameter prompt: The prompt to send to the AI
    /// - Returns: The generated text response
    /// - Throws: TextGenerationError.noAPIKey if no API key is configured, or provider-specific errors
    @MainActor
    func generateText(prompt: String) async throws -> String {
        let settings = AISettingsManager.shared

        switch settings.selectedProvider {
        case .openAI:
            return try await OpenAIService.shared.generateText(
                prompt: prompt,
                model: settings.selectedOpenAIModel
            )
        case .claude:
            return try await ClaudeAPIService.shared.generateText(
                prompt: prompt,
                model: settings.selectedClaudeModel
            )
        }
    }
}