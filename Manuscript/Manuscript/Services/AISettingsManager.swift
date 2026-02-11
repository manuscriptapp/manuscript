import Foundation
import SwiftUI

/// AI provider options
enum AIModelProvider: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    case ollama = "ollama"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .gemini: return "Google Gemini"
        case .ollama: return "Ollama (Local)"
        }
    }

    var description: String {
        switch self {
        case .openAI:
            return "GPT models via your OpenAI API key."
        case .anthropic:
            return "Claude models via your Anthropic API key."
        case .gemini:
            return "Gemini models via your Google AI API key."
        case .ollama:
            return "Run models locally with Ollama. No API key needed."
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .openAI, .anthropic, .gemini: return true
        case .ollama: return false
        }
    }
}

/// Available model for any provider
struct AIModel: Identifiable, Hashable {
    let id: String
    let displayName: String
    let description: String
    let provider: AIModelProvider

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(provider)
    }

    static func == (lhs: AIModel, rhs: AIModel) -> Bool {
        lhs.id == rhs.id && lhs.provider == rhs.provider
    }
}

/// Model catalogs per provider
enum AIModelCatalog {
    static let openAI: [AIModel] = [
        AIModel(id: "gpt-4o", displayName: "GPT-4o (Recommended)", description: "Most capable multimodal model", provider: .openAI),
        AIModel(id: "gpt-4o-mini", displayName: "GPT-4o Mini (Fast & Affordable)", description: "Great balance of speed, quality, and cost", provider: .openAI),
        AIModel(id: "o3", displayName: "o3 (Advanced Reasoning)", description: "Best for deep reasoning and multi-step tasks", provider: .openAI),
        AIModel(id: "o4-mini", displayName: "o4-mini (Fast Reasoning)", description: "Fast reasoning model for everyday tasks", provider: .openAI),
        AIModel(id: "gpt-4.1", displayName: "GPT-4.1", description: "High-quality coding and instruction following", provider: .openAI),
        AIModel(id: "gpt-4.1-mini", displayName: "GPT-4.1 Mini", description: "Efficient general-purpose model", provider: .openAI),
    ]

    static let anthropic: [AIModel] = [
        AIModel(id: "claude-sonnet-4-5-20250514", displayName: "Claude 4.5 Sonnet (Recommended)", description: "Best balance of quality, speed, and cost", provider: .anthropic),
        AIModel(id: "claude-opus-4-20250514", displayName: "Claude Opus 4 (Most Capable)", description: "Most intelligent, best for complex creative writing", provider: .anthropic),
        AIModel(id: "claude-sonnet-4-20250514", displayName: "Claude Sonnet 4", description: "Excellent balance of speed and capability", provider: .anthropic),
        AIModel(id: "claude-3-5-sonnet-20241022", displayName: "Claude 3.5 Sonnet", description: "Great all-around model", provider: .anthropic),
        AIModel(id: "claude-3-5-haiku-20241022", displayName: "Claude 3.5 Haiku (Fast)", description: "Fast responses, lower cost", provider: .anthropic),
    ]

    static let gemini: [AIModel] = [
        AIModel(id: "gemini-2.5-flash", displayName: "Gemini 2.5 Flash (Recommended)", description: "Fast and versatile with great quality", provider: .gemini),
        AIModel(id: "gemini-2.5-pro", displayName: "Gemini 2.5 Pro", description: "Most capable Gemini model with thinking", provider: .gemini),
        AIModel(id: "gemini-2.0-flash", displayName: "Gemini 2.0 Flash", description: "Previous generation, fast and reliable", provider: .gemini),
        AIModel(id: "gemini-1.5-pro", displayName: "Gemini 1.5 Pro", description: "Large context window, solid quality", provider: .gemini),
        AIModel(id: "gemini-1.5-flash", displayName: "Gemini 1.5 Flash", description: "Fast and cost effective", provider: .gemini),
    ]

    static let ollama: [AIModel] = [
        AIModel(id: "llama3.3", displayName: "Llama 3.3 (Recommended)", description: "Meta's latest open model, great quality", provider: .ollama),
        AIModel(id: "llama3.2", displayName: "Llama 3.2", description: "Compact and fast local model", provider: .ollama),
        AIModel(id: "mistral", displayName: "Mistral", description: "Strong European open model", provider: .ollama),
        AIModel(id: "qwen2.5", displayName: "Qwen 2.5", description: "Alibaba's high-quality open model", provider: .ollama),
        AIModel(id: "phi-4", displayName: "Phi-4", description: "Microsoft's compact reasoning model", provider: .ollama),
        AIModel(id: "gemma2", displayName: "Gemma 2", description: "Google's open model for local use", provider: .ollama),
    ]

    static func models(for provider: AIModelProvider) -> [AIModel] {
        switch provider {
        case .openAI: return openAI
        case .anthropic: return anthropic
        case .gemini: return gemini
        case .ollama: return ollama
        }
    }

    static func defaultModel(for provider: AIModelProvider) -> AIModel {
        models(for: provider).first!
    }
}

/// Observable manager for AI settings
@MainActor
@Observable
final class AISettingsManager {
    static let shared = AISettingsManager()

    private let keychain = KeychainService.shared
    private let userDefaults = UserDefaults.standard

    private enum DefaultsKey {
        static let modelProvider = "ai_model_provider"
        static let openAIModel = "ai_openai_model"
        static let anthropicModel = "ai_anthropic_model"
        static let geminiModel = "ai_gemini_model"
        static let ollamaModel = "ai_ollama_model"
        static let ollamaHost = "ai_ollama_host"
    }

    // MARK: - Properties

    var selectedProvider: AIModelProvider {
        didSet {
            userDefaults.set(selectedProvider.rawValue, forKey: DefaultsKey.modelProvider)
        }
    }

    var selectedModelId: [AIModelProvider: String] = [:] {
        didSet {
            for (provider, modelId) in selectedModelId {
                let key: String
                switch provider {
                case .openAI: key = DefaultsKey.openAIModel
                case .anthropic: key = DefaultsKey.anthropicModel
                case .gemini: key = DefaultsKey.geminiModel
                case .ollama: key = DefaultsKey.ollamaModel
                }
                userDefaults.set(modelId, forKey: key)
            }
        }
    }

    var ollamaHost: String {
        didSet {
            userDefaults.set(ollamaHost, forKey: DefaultsKey.ollamaHost)
        }
    }

    // MARK: - Computed Properties

    var selectedModel: AIModel {
        let modelId = selectedModelId[selectedProvider] ?? AIModelCatalog.defaultModel(for: selectedProvider).id
        let models = AIModelCatalog.models(for: selectedProvider)
        return models.first(where: { $0.id == modelId }) ?? AIModelCatalog.defaultModel(for: selectedProvider)
    }

    func selectedModel(for provider: AIModelProvider) -> AIModel {
        let modelId = selectedModelId[provider] ?? AIModelCatalog.defaultModel(for: provider).id
        let models = AIModelCatalog.models(for: provider)
        return models.first(where: { $0.id == modelId }) ?? AIModelCatalog.defaultModel(for: provider)
    }

    var hasOpenAIKey: Bool { keychain.exists(.openAIAPIKey) }
    var hasAnthropicKey: Bool { keychain.exists(.claudeAPIKey) }
    var hasGeminiKey: Bool { keychain.exists(.geminiAPIKey) }

    var hasAPIKeyForSelectedProvider: Bool {
        switch selectedProvider {
        case .openAI: return hasOpenAIKey
        case .anthropic: return hasAnthropicKey
        case .gemini: return hasGeminiKey
        case .ollama: return true
        }
    }

    var hasAnyAPIKey: Bool {
        hasOpenAIKey || hasAnthropicKey || hasGeminiKey
    }

    // MARK: - Key Previews

    func keyPreview(for provider: AIModelProvider) -> String {
        let keychainKey: KeychainService.KeychainKey
        switch provider {
        case .openAI: keychainKey = .openAIAPIKey
        case .anthropic: keychainKey = .claudeAPIKey
        case .gemini: keychainKey = .geminiAPIKey
        case .ollama: return ""
        }

        guard let key = try? keychain.retrieve(keychainKey), !key.isEmpty else {
            return ""
        }
        if key.count > 12 {
            return "\(String(key.prefix(8)))...\(String(key.suffix(4)))"
        }
        return key
    }

    // MARK: - Initialization

    private init() {
        // Load Ollama host
        self.ollamaHost = userDefaults.string(forKey: DefaultsKey.ollamaHost) ?? "http://localhost:11434"

        // Load selected models per provider
        var modelIds: [AIModelProvider: String] = [:]
        if let id = userDefaults.string(forKey: DefaultsKey.openAIModel) { modelIds[.openAI] = id }
        if let id = userDefaults.string(forKey: DefaultsKey.anthropicModel) { modelIds[.anthropic] = id }
        if let id = userDefaults.string(forKey: DefaultsKey.geminiModel) { modelIds[.gemini] = id }
        if let id = userDefaults.string(forKey: DefaultsKey.ollamaModel) { modelIds[.ollama] = id }
        self.selectedModelId = modelIds

        // Load provider - default to Ollama if no API keys are configured
        if let providerRaw = userDefaults.string(forKey: DefaultsKey.modelProvider),
           let provider = AIModelProvider(rawValue: providerRaw) {
            self.selectedProvider = provider
        } else {
            // Smart default: use the first provider that has an API key, or Ollama if none
            let keychain = KeychainService.shared
            if keychain.exists(.openAIAPIKey) {
                self.selectedProvider = .openAI
            } else if keychain.exists(.claudeAPIKey) {
                self.selectedProvider = .anthropic
            } else if keychain.exists(.geminiAPIKey) {
                self.selectedProvider = .gemini
            } else {
                self.selectedProvider = .ollama
            }
        }
    }

    // MARK: - API Key Management

    func saveAPIKey(_ key: String, for provider: AIModelProvider) throws {
        let keychainKey: KeychainService.KeychainKey
        switch provider {
        case .openAI: keychainKey = .openAIAPIKey
        case .anthropic: keychainKey = .claudeAPIKey
        case .gemini: keychainKey = .geminiAPIKey
        case .ollama: return
        }

        if key.isEmpty {
            try keychain.delete(keychainKey)
        } else {
            try keychain.save(key, for: keychainKey)
        }
    }

    func getAPIKey(for provider: AIModelProvider) -> String? {
        let keychainKey: KeychainService.KeychainKey
        switch provider {
        case .openAI: keychainKey = .openAIAPIKey
        case .anthropic: keychainKey = .claudeAPIKey
        case .gemini: keychainKey = .geminiAPIKey
        case .ollama: return nil
        }
        return try? keychain.retrieve(keychainKey)
    }

    func deleteAPIKey(for provider: AIModelProvider) throws {
        let keychainKey: KeychainService.KeychainKey
        switch provider {
        case .openAI: keychainKey = .openAIAPIKey
        case .anthropic: keychainKey = .claudeAPIKey
        case .gemini: keychainKey = .geminiAPIKey
        case .ollama: return
        }
        try keychain.delete(keychainKey)
    }

    func hasAPIKey(for provider: AIModelProvider) -> Bool {
        switch provider {
        case .openAI: return hasOpenAIKey
        case .anthropic: return hasAnthropicKey
        case .gemini: return hasGeminiKey
        case .ollama: return true
        }
    }
}
