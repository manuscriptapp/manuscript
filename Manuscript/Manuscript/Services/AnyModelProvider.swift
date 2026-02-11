import Foundation

// MARK: - AnyModel Protocol

/// Protocol that all AI model providers must conform to.
/// This enables a unified interface across OpenAI, Claude, Gemini, Grok, DeepSeek, and local models.
protocol AnyModelProvider: Sendable {
    /// Generate text from a prompt
    func generateText(
        prompt: String,
        systemPrompt: String?,
        modelId: String,
        temperature: Double,
        maxTokens: Int?
    ) async throws -> String

    /// Test the provider connection
    func testConnection() async throws -> Bool
}

// MARK: - Unified Model Descriptor

/// A model descriptor that works across all providers
struct AnyModel: Identifiable, Hashable, Codable {
    let id: String          // e.g. "gpt-5", "claude-sonnet-4-5", "gemini-2.5-pro"
    let name: String        // Human-readable name
    let provider: ModelProviderKind
    let subtitle: String    // Short description
    let isDefault: Bool     // Whether this is the default model for its provider

    var displayName: String {
        if isDefault {
            return "\(name) (Recommended)"
        }
        return name
    }
}

// MARK: - Provider Enumeration

/// All supported AI model providers
enum ModelProviderKind: String, CaseIterable, Identifiable, Codable {
    case local = "local"
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    case grok = "grok"
    case deepSeek = "deepseek"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local:      return "Local (Ollama)"
        case .openAI:     return "OpenAI"
        case .anthropic:  return "Anthropic (Claude)"
        case .gemini:     return "Google Gemini"
        case .grok:       return "xAI (Grok)"
        case .deepSeek:   return "DeepSeek"
        }
    }

    var description: String {
        switch self {
        case .local:
            return "Run models locally on your device using Ollama. No API key required. Private and free."
        case .openAI:
            return "Use your own OpenAI API key for GPT models."
        case .anthropic:
            return "Use your own Anthropic API key for Claude models."
        case .gemini:
            return "Use your own Google AI API key for Gemini models."
        case .grok:
            return "Use your own xAI API key for Grok models."
        case .deepSeek:
            return "Use your own DeepSeek API key for DeepSeek models."
        }
    }

    var requiresAPIKey: Bool {
        self != .local
    }

    var iconName: String {
        switch self {
        case .local:      return "desktopcomputer"
        case .openAI:     return "brain.head.profile"
        case .anthropic:  return "brain"
        case .gemini:     return "sparkles"
        case .grok:       return "bolt.fill"
        case .deepSeek:   return "water.waves"
        }
    }
}

// MARK: - Model Registry

/// Central registry of all available models across all providers
enum AnyModelRegistry {

    // MARK: - OpenAI Models

    static let openAIModels: [AnyModel] = [
        AnyModel(id: "gpt-5", name: "GPT-5", provider: .openAI,
                 subtitle: "Most capable general-purpose model", isDefault: true),
        AnyModel(id: "gpt-5-mini", name: "GPT-5 Mini", provider: .openAI,
                 subtitle: "Great balance of speed, quality, and cost", isDefault: false),
        AnyModel(id: "gpt-5-nano", name: "GPT-5 Nano", provider: .openAI,
                 subtitle: "Ultra-fast responses at the lowest cost", isDefault: false),
        AnyModel(id: "o3", name: "o3", provider: .openAI,
                 subtitle: "Best for deep reasoning and multi-step tasks", isDefault: false),
        AnyModel(id: "o4-mini", name: "o4-mini", provider: .openAI,
                 subtitle: "Fast reasoning model for everyday tasks", isDefault: false),
        AnyModel(id: "gpt-4.1", name: "GPT-4.1", provider: .openAI,
                 subtitle: "High-quality previous-generation flagship", isDefault: false),
        AnyModel(id: "gpt-4.1-mini", name: "GPT-4.1 Mini", provider: .openAI,
                 subtitle: "Efficient previous-generation model", isDefault: false),
    ]

    // MARK: - Anthropic Models

    static let anthropicModels: [AnyModel] = [
        AnyModel(id: "claude-sonnet-4-5", name: "Claude 4.5 Sonnet", provider: .anthropic,
                 subtitle: "Best balance of quality, speed, and cost", isDefault: true),
        AnyModel(id: "claude-opus-4-20250514", name: "Claude 4 Opus", provider: .anthropic,
                 subtitle: "Most intelligent, best for complex creative writing", isDefault: false),
        AnyModel(id: "claude-sonnet-4-20250514", name: "Claude 4 Sonnet", provider: .anthropic,
                 subtitle: "Excellent balance of speed and capability", isDefault: false),
        AnyModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", provider: .anthropic,
                 subtitle: "Great all-around model", isDefault: false),
        AnyModel(id: "claude-3-5-haiku-20241022", name: "Claude 3.5 Haiku", provider: .anthropic,
                 subtitle: "Fast responses, lower cost", isDefault: false),
    ]

    // MARK: - Gemini Models

    static let geminiModels: [AnyModel] = [
        AnyModel(id: "gemini-2.5-pro", name: "Gemini 2.5 Pro", provider: .gemini,
                 subtitle: "Most capable Gemini model with thinking", isDefault: true),
        AnyModel(id: "gemini-2.5-flash", name: "Gemini 2.5 Flash", provider: .gemini,
                 subtitle: "Fast and efficient with thinking", isDefault: false),
        AnyModel(id: "gemini-2.0-flash", name: "Gemini 2.0 Flash", provider: .gemini,
                 subtitle: "Previous-generation fast model", isDefault: false),
        AnyModel(id: "gemini-2.0-flash-lite", name: "Gemini 2.0 Flash Lite", provider: .gemini,
                 subtitle: "Lightweight and cost-efficient", isDefault: false),
    ]

    // MARK: - Grok Models

    static let grokModels: [AnyModel] = [
        AnyModel(id: "grok-3", name: "Grok 3", provider: .grok,
                 subtitle: "Most capable Grok model", isDefault: true),
        AnyModel(id: "grok-3-fast", name: "Grok 3 Fast", provider: .grok,
                 subtitle: "Faster inference with Grok 3", isDefault: false),
        AnyModel(id: "grok-3-mini", name: "Grok 3 Mini", provider: .grok,
                 subtitle: "Lightweight reasoning model", isDefault: false),
        AnyModel(id: "grok-3-mini-fast", name: "Grok 3 Mini Fast", provider: .grok,
                 subtitle: "Fastest Grok model", isDefault: false),
    ]

    // MARK: - DeepSeek Models

    static let deepSeekModels: [AnyModel] = [
        AnyModel(id: "deepseek-chat", name: "DeepSeek V3", provider: .deepSeek,
                 subtitle: "Powerful general-purpose model", isDefault: true),
        AnyModel(id: "deepseek-reasoner", name: "DeepSeek R1", provider: .deepSeek,
                 subtitle: "Advanced reasoning model", isDefault: false),
    ]

    // MARK: - Local Models (Ollama)

    static let localModels: [AnyModel] = [
        AnyModel(id: "llama3.2", name: "Llama 3.2", provider: .local,
                 subtitle: "Meta's latest open model (3B)", isDefault: true),
        AnyModel(id: "llama3.1", name: "Llama 3.1", provider: .local,
                 subtitle: "Meta's open model (8B)", isDefault: false),
        AnyModel(id: "mistral", name: "Mistral 7B", provider: .local,
                 subtitle: "Fast and capable open model", isDefault: false),
        AnyModel(id: "gemma2", name: "Gemma 2", provider: .local,
                 subtitle: "Google's open model", isDefault: false),
        AnyModel(id: "phi3", name: "Phi-3", provider: .local,
                 subtitle: "Microsoft's compact model", isDefault: false),
        AnyModel(id: "qwen2.5", name: "Qwen 2.5", provider: .local,
                 subtitle: "Alibaba's open model", isDefault: false),
    ]

    // MARK: - Lookup Helpers

    /// All models across all providers
    static var allModels: [AnyModel] {
        openAIModels + anthropicModels + geminiModels + grokModels + deepSeekModels + localModels
    }

    /// Get models for a specific provider
    static func models(for provider: ModelProviderKind) -> [AnyModel] {
        switch provider {
        case .openAI:    return openAIModels
        case .anthropic: return anthropicModels
        case .gemini:    return geminiModels
        case .grok:      return grokModels
        case .deepSeek:  return deepSeekModels
        case .local:     return localModels
        }
    }

    /// Get the default model for a provider
    static func defaultModel(for provider: ModelProviderKind) -> AnyModel {
        models(for: provider).first(where: { $0.isDefault }) ?? models(for: provider)[0]
    }

    /// Find a model by its id
    static func model(withId id: String) -> AnyModel? {
        allModels.first(where: { $0.id == id })
    }
}

// MARK: - Unified Error Type

enum AnyModelError: LocalizedError {
    case noAPIKey(ModelProviderKind)
    case invalidAPIKey(ModelProviderKind)
    case invalidResponse
    case httpError(Int, String)
    case decodingError(Error)
    case networkError(Error)
    case rateLimited
    case overloaded
    case localModelUnavailable(String)
    case ollamaNotRunning

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let provider):
            return "No API key configured for \(provider.displayName). Please add your API key in Settings."
        case .invalidAPIKey(let provider):
            return "Invalid API key for \(provider.displayName). Please check your key in Settings."
        case .invalidResponse:
            return "Invalid response from AI provider."
        case .httpError(let code, let message):
            return "API error (\(code)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limited. Please wait a moment and try again."
        case .overloaded:
            return "The AI service is currently overloaded. Please try again later."
        case .localModelUnavailable(let model):
            return "Local model '\(model)' is not available. Pull it with: ollama pull \(model)"
        case .ollamaNotRunning:
            return "Ollama is not running. Please start Ollama to use local models."
        }
    }
}
