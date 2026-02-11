import Foundation
import SwiftUI

/// AI provider options
enum AIModelProvider: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    case apple = "apple"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .gemini: return "Google Gemini"
        case .apple: return "Apple Intelligence"
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
        case .apple:
            return "On-device AI powered by Apple Intelligence. No API key or internet required."
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .openAI, .anthropic, .gemini: return true
        case .apple: return false
        }
    }

    /// Whether this provider is available on the current device
    var isAvailable: Bool {
        switch self {
        case .openAI, .anthropic, .gemini: return true
        case .apple:
            if #available(iOS 26, macOS 26, *) {
                return true
            }
            return false
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

    static let apple: [AIModel] = [
        AIModel(id: "default", displayName: "Apple Foundation Model", description: "On-device language model via Apple Intelligence", provider: .apple),
    ]

    static func models(for provider: AIModelProvider) -> [AIModel] {
        switch provider {
        case .openAI: return openAI
        case .anthropic: return anthropic
        case .gemini: return gemini
        case .apple: return apple
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
                case .apple: continue
                }
                userDefaults.set(modelId, forKey: key)
            }
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
        case .apple: return true
        }
    }

    /// Whether any AI provider is usable (has API key or Foundation Models available)
    var hasAnyProviderAvailable: Bool {
        hasAnyAPIKey || AIModelProvider.apple.isAvailable
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
        case .apple: return ""
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
        // Load selected models per provider
        var modelIds: [AIModelProvider: String] = [:]
        if let id = userDefaults.string(forKey: DefaultsKey.openAIModel) { modelIds[.openAI] = id }
        if let id = userDefaults.string(forKey: DefaultsKey.anthropicModel) { modelIds[.anthropic] = id }
        if let id = userDefaults.string(forKey: DefaultsKey.geminiModel) { modelIds[.gemini] = id }
        self.selectedModelId = modelIds

        // Load provider - default to Apple Intelligence if available, else first configured cloud provider
        if let providerRaw = userDefaults.string(forKey: DefaultsKey.modelProvider),
           let provider = AIModelProvider(rawValue: providerRaw) {
            self.selectedProvider = provider
        } else {
            // Smart default: use Apple Intelligence if available, else first provider with an API key
            let keychain = KeychainService.shared
            if AIModelProvider.apple.isAvailable {
                self.selectedProvider = .apple
            } else if keychain.exists(.openAIAPIKey) {
                self.selectedProvider = .openAI
            } else if keychain.exists(.claudeAPIKey) {
                self.selectedProvider = .anthropic
            } else if keychain.exists(.geminiAPIKey) {
                self.selectedProvider = .gemini
            } else {
                // No provider available - default to Apple (will show warning)
                self.selectedProvider = .apple
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
        case .apple: return
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
        case .apple: return nil
        }
        return try? keychain.retrieve(keychainKey)
    }

    func deleteAPIKey(for provider: AIModelProvider) throws {
        let keychainKey: KeychainService.KeychainKey
        switch provider {
        case .openAI: keychainKey = .openAIAPIKey
        case .anthropic: keychainKey = .claudeAPIKey
        case .gemini: keychainKey = .geminiAPIKey
        case .apple: return
        }
        try keychain.delete(keychainKey)
    }

    func hasAPIKey(for provider: AIModelProvider) -> Bool {
        switch provider {
        case .openAI: return hasOpenAIKey
        case .anthropic: return hasAnthropicKey
        case .gemini: return hasGeminiKey
        case .apple: return true
        }
    }
}
