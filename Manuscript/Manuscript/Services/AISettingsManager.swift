import Foundation
import SwiftUI

/// Model provider options for AI text generation.
/// Kept for backward compatibility with existing code that references AIModelProvider.
/// New code should use ModelProviderKind instead.
enum AIModelProvider: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case claude = "claude"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .claude:
            return "Claude (Anthropic)"
        }
    }

    var description: String {
        switch self {
        case .openAI:
            return "Use your own OpenAI API key for direct access."
        case .claude:
            return "Use your own Claude API key for direct access."
        }
    }
}

/// Available OpenAI models - kept for backward compatibility.
/// New code should use AnyModelRegistry.openAIModels instead.
enum OpenAIModel: String, CaseIterable, Identifiable {
    case gpt5 = "gpt-5"
    case gpt5Mini = "gpt-5-mini"
    case gpt5Nano = "gpt-5-nano"
    case o3 = "o3"
    case o4Mini = "o4-mini"
    case gpt41 = "gpt-4.1"
    case gpt41Mini = "gpt-4.1-mini"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gpt5:
            return "GPT-5 (Recommended)"
        case .gpt5Mini:
            return "GPT-5 Mini (Fast & Affordable)"
        case .gpt5Nano:
            return "GPT-5 Nano (Lowest Cost)"
        case .o3:
            return "o3 (Advanced Reasoning)"
        case .o4Mini:
            return "o4-mini (Fast Reasoning)"
        case .gpt41:
            return "GPT-4.1"
        case .gpt41Mini:
            return "GPT-4.1 Mini"
        }
    }

    var description: String {
        switch self {
        case .gpt5:
            return "Most capable general-purpose model"
        case .gpt5Mini:
            return "Great balance of speed, quality, and cost"
        case .gpt5Nano:
            return "Ultra-fast responses at the lowest cost"
        case .o3:
            return "Best for deep reasoning and multi-step tasks"
        case .o4Mini:
            return "Fast reasoning model for everyday tasks"
        case .gpt41:
            return "High-quality previous-generation flagship"
        case .gpt41Mini:
            return "Efficient previous-generation general model"
        }
    }
}

/// Available Claude models - kept for backward compatibility.
/// New code should use AnyModelRegistry.anthropicModels instead.
enum ClaudeModel: String, CaseIterable, Identifiable {
    case claude45Sonnet = "claude-sonnet-4-5"
    case claude4Opus = "claude-opus-4-20250514"
    case claude4Sonnet = "claude-sonnet-4-20250514"
    case claude35Sonnet = "claude-3-5-sonnet-20241022"
    case claude35Haiku = "claude-3-5-haiku-20241022"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude45Sonnet:
            return "Claude 4.5 Sonnet (Recommended)"
        case .claude4Opus:
            return "Claude 4 Opus (Most Capable)"
        case .claude4Sonnet:
            return "Claude 4 Sonnet"
        case .claude35Sonnet:
            return "Claude 3.5 Sonnet"
        case .claude35Haiku:
            return "Claude 3.5 Haiku (Fast)"
        }
    }

    var description: String {
        switch self {
        case .claude45Sonnet:
            return "Best balance of quality, speed, and cost"
        case .claude4Opus:
            return "Most intelligent, best for complex creative writing"
        case .claude4Sonnet:
            return "Excellent balance of speed and capability"
        case .claude35Sonnet:
            return "Great all-around model"
        case .claude35Haiku:
            return "Fast responses, lower cost"
        }
    }
}

/// Observable manager for AI settings.
/// Supports all providers: Local (Ollama), OpenAI, Anthropic, Gemini, Grok, DeepSeek.
/// Defaults to local models when no API keys are configured.
@MainActor
@Observable
final class AISettingsManager {
    static let shared = AISettingsManager()

    private let keychain = KeychainService.shared
    private let userDefaults = UserDefaults.standard

    // Keys for UserDefaults
    private enum DefaultsKey {
        static let modelProvider = "ai_model_provider"
        static let openAIModel = "ai_openai_model"
        static let claudeModel = "ai_claude_model"

        // AnyModel keys
        static let selectedProviderKind = "ai_provider_kind"
        static let selectedModelId = "ai_selected_model_id"
        static let ollamaEndpoint = "ai_ollama_endpoint"
        static let ollamaCustomModel = "ai_ollama_custom_model"
    }

    // MARK: - AnyModel Properties

    /// The currently selected provider
    var selectedProviderKind: ModelProviderKind {
        didSet {
            userDefaults.set(selectedProviderKind.rawValue, forKey: DefaultsKey.selectedProviderKind)
            // When provider changes, select its default model
            if selectedModelId == nil || AnyModelRegistry.model(withId: selectedModelId!)?.provider != selectedProviderKind {
                selectedModelId = AnyModelRegistry.defaultModel(for: selectedProviderKind).id
            }
        }
    }

    /// The currently selected model ID
    var selectedModelId: String? {
        didSet {
            if let id = selectedModelId {
                userDefaults.set(id, forKey: DefaultsKey.selectedModelId)
            }
        }
    }

    /// Custom Ollama endpoint URL
    var ollamaEndpoint: String {
        didSet {
            userDefaults.set(ollamaEndpoint, forKey: DefaultsKey.ollamaEndpoint)
        }
    }

    /// Custom model name for Ollama (when user wants a model not in the preset list)
    var ollamaCustomModel: String {
        didSet {
            userDefaults.set(ollamaCustomModel, forKey: DefaultsKey.ollamaCustomModel)
        }
    }

    /// The resolved AnyModel for the current selection
    var selectedModel: AnyModel {
        if let id = selectedModelId, let model = AnyModelRegistry.model(withId: id) {
            return model
        }
        return AnyModelRegistry.defaultModel(for: selectedProviderKind)
    }

    /// Available models for the current provider
    var availableModels: [AnyModel] {
        AnyModelRegistry.models(for: selectedProviderKind)
    }

    // MARK: - Legacy Compatibility Properties

    var selectedProvider: AIModelProvider {
        get {
            switch selectedProviderKind {
            case .openAI: return .openAI
            case .anthropic: return .claude
            default: return .openAI
            }
        }
        set {
            switch newValue {
            case .openAI: selectedProviderKind = .openAI
            case .claude: selectedProviderKind = .anthropic
            }
        }
    }

    var selectedOpenAIModel: OpenAIModel {
        get {
            if let raw = userDefaults.string(forKey: DefaultsKey.openAIModel),
               let model = OpenAIModel(rawValue: raw) {
                return model
            }
            return .gpt5
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: DefaultsKey.openAIModel)
        }
    }

    var selectedClaudeModel: ClaudeModel {
        get {
            if let raw = userDefaults.string(forKey: DefaultsKey.claudeModel),
               let model = ClaudeModel(rawValue: raw) {
                return model
            }
            return .claude45Sonnet
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: DefaultsKey.claudeModel)
        }
    }

    // MARK: - API Key Checks

    var hasOpenAIKey: Bool {
        keychain.exists(.openAIAPIKey)
    }

    var hasClaudeKey: Bool {
        keychain.exists(.claudeAPIKey)
    }

    var hasGeminiKey: Bool {
        keychain.exists(.geminiAPIKey)
    }

    var hasGrokKey: Bool {
        keychain.exists(.grokAPIKey)
    }

    var hasDeepSeekKey: Bool {
        keychain.exists(.deepSeekAPIKey)
    }

    /// Returns true if any cloud API key is configured
    var hasAnyAPIKey: Bool {
        hasOpenAIKey || hasClaudeKey || hasGeminiKey || hasGrokKey || hasDeepSeekKey
    }

    /// Returns true if the currently selected provider has its API key configured (or is local)
    var hasAPIKeyForSelectedProvider: Bool {
        switch selectedProviderKind {
        case .local:     return true
        case .openAI:    return hasOpenAIKey
        case .anthropic: return hasClaudeKey
        case .gemini:    return hasGeminiKey
        case .grok:      return hasGrokKey
        case .deepSeek:  return hasDeepSeekKey
        }
    }

    /// Check if a specific provider has its key set
    func hasAPIKey(for provider: ModelProviderKind) -> Bool {
        switch provider {
        case .local:     return true
        case .openAI:    return hasOpenAIKey
        case .anthropic: return hasClaudeKey
        case .gemini:    return hasGeminiKey
        case .grok:      return hasGrokKey
        case .deepSeek:  return hasDeepSeekKey
        }
    }

    // MARK: - Key Previews

    var openAIKeyPreview: String { keyPreview(for: .openAIAPIKey) }
    var claudeKeyPreview: String { keyPreview(for: .claudeAPIKey) }
    var geminiKeyPreview: String { keyPreview(for: .geminiAPIKey) }
    var grokKeyPreview: String { keyPreview(for: .grokAPIKey) }
    var deepSeekKeyPreview: String { keyPreview(for: .deepSeekAPIKey) }

    func keyPreview(for provider: ModelProviderKind) -> String {
        switch provider {
        case .local:     return ""
        case .openAI:    return openAIKeyPreview
        case .anthropic: return claudeKeyPreview
        case .gemini:    return geminiKeyPreview
        case .grok:      return grokKeyPreview
        case .deepSeek:  return deepSeekKeyPreview
        }
    }

    private func keyPreview(for key: KeychainService.KeychainKey) -> String {
        guard let value = try? keychain.retrieve(key), !value.isEmpty else {
            return ""
        }
        if value.count > 12 {
            let prefix = String(value.prefix(8))
            let suffix = String(value.suffix(4))
            return "\(prefix)...\(suffix)"
        }
        return value
    }

    // MARK: - Initialization

    private init() {
        // Load AnyModel provider selection
        if let providerRaw = userDefaults.string(forKey: DefaultsKey.selectedProviderKind),
           let provider = ModelProviderKind(rawValue: providerRaw) {
            self.selectedProviderKind = provider
        } else if let legacyRaw = userDefaults.string(forKey: DefaultsKey.modelProvider) {
            // Migrate from legacy provider setting
            switch legacyRaw {
            case "openai": self.selectedProviderKind = .openAI
            case "claude": self.selectedProviderKind = .anthropic
            default: self.selectedProviderKind = .local
            }
        } else {
            // Default to local models when no provider is configured
            self.selectedProviderKind = .local
        }

        // Load selected model
        if let modelId = userDefaults.string(forKey: DefaultsKey.selectedModelId) {
            self.selectedModelId = modelId
        } else {
            // Migrate from legacy model settings or set default
            self.selectedModelId = AnyModelRegistry.defaultModel(for: selectedProviderKind).id
        }

        // Load Ollama configuration
        self.ollamaEndpoint = userDefaults.string(forKey: DefaultsKey.ollamaEndpoint) ?? "http://localhost:11434"
        self.ollamaCustomModel = userDefaults.string(forKey: DefaultsKey.ollamaCustomModel) ?? ""
    }

    // MARK: - API Key Management

    func saveOpenAIKey(_ key: String) throws {
        if key.isEmpty {
            try keychain.delete(.openAIAPIKey)
        } else {
            try keychain.save(key, for: .openAIAPIKey)
        }
    }

    func saveClaudeKey(_ key: String) throws {
        if key.isEmpty {
            try keychain.delete(.claudeAPIKey)
        } else {
            try keychain.save(key, for: .claudeAPIKey)
        }
    }

    func saveGeminiKey(_ key: String) throws {
        if key.isEmpty {
            try keychain.delete(.geminiAPIKey)
        } else {
            try keychain.save(key, for: .geminiAPIKey)
        }
    }

    func saveGrokKey(_ key: String) throws {
        if key.isEmpty {
            try keychain.delete(.grokAPIKey)
        } else {
            try keychain.save(key, for: .grokAPIKey)
        }
    }

    func saveDeepSeekKey(_ key: String) throws {
        if key.isEmpty {
            try keychain.delete(.deepSeekAPIKey)
        } else {
            try keychain.save(key, for: .deepSeekAPIKey)
        }
    }

    func getOpenAIKey() -> String? { try? keychain.retrieve(.openAIAPIKey) }
    func getClaudeKey() -> String? { try? keychain.retrieve(.claudeAPIKey) }
    func getGeminiKey() -> String? { try? keychain.retrieve(.geminiAPIKey) }
    func getGrokKey() -> String? { try? keychain.retrieve(.grokAPIKey) }
    func getDeepSeekKey() -> String? { try? keychain.retrieve(.deepSeekAPIKey) }

    func deleteOpenAIKey() throws { try keychain.delete(.openAIAPIKey) }
    func deleteClaudeKey() throws { try keychain.delete(.claudeAPIKey) }
    func deleteGeminiKey() throws { try keychain.delete(.geminiAPIKey) }
    func deleteGrokKey() throws { try keychain.delete(.grokAPIKey) }
    func deleteDeepSeekKey() throws { try keychain.delete(.deepSeekAPIKey) }

    /// Save API key for a given provider
    func saveAPIKey(_ key: String, for provider: ModelProviderKind) throws {
        switch provider {
        case .local:     return
        case .openAI:    try saveOpenAIKey(key)
        case .anthropic: try saveClaudeKey(key)
        case .gemini:    try saveGeminiKey(key)
        case .grok:      try saveGrokKey(key)
        case .deepSeek:  try saveDeepSeekKey(key)
        }
    }

    /// Delete API key for a given provider
    func deleteAPIKey(for provider: ModelProviderKind) throws {
        switch provider {
        case .local:     return
        case .openAI:    try deleteOpenAIKey()
        case .anthropic: try deleteClaudeKey()
        case .gemini:    try deleteGeminiKey()
        case .grok:      try deleteGrokKey()
        case .deepSeek:  try deleteDeepSeekKey()
        }
    }
}
