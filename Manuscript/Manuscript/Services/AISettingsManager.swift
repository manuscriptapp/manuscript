import Foundation
import SwiftUI

/// Model provider options for AI text generation
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

/// Available OpenAI models
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

/// Available Claude models
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

/// Observable manager for AI settings
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
    }

    // MARK: - Published Properties

    var selectedProvider: AIModelProvider {
        didSet {
            userDefaults.set(selectedProvider.rawValue, forKey: DefaultsKey.modelProvider)
        }
    }

    var selectedOpenAIModel: OpenAIModel {
        didSet {
            userDefaults.set(selectedOpenAIModel.rawValue, forKey: DefaultsKey.openAIModel)
        }
    }

    var selectedClaudeModel: ClaudeModel {
        didSet {
            userDefaults.set(selectedClaudeModel.rawValue, forKey: DefaultsKey.claudeModel)
        }
    }

    // MARK: - Computed Properties

    var hasOpenAIKey: Bool {
        keychain.exists(.openAIAPIKey)
    }

    var hasClaudeKey: Bool {
        keychain.exists(.claudeAPIKey)
    }

    /// Returns true if the currently selected provider has an API key configured
    var hasAPIKeyForSelectedProvider: Bool {
        switch selectedProvider {
        case .openAI:
            return hasOpenAIKey
        case .claude:
            return hasClaudeKey
        }
    }

    var openAIKeyPreview: String {
        guard let key = try? keychain.retrieve(.openAIAPIKey), !key.isEmpty else {
            return ""
        }
        // Show first 8 and last 4 characters
        if key.count > 12 {
            let prefix = String(key.prefix(8))
            let suffix = String(key.suffix(4))
            return "\(prefix)...\(suffix)"
        }
        return key
    }

    var claudeKeyPreview: String {
        guard let key = try? keychain.retrieve(.claudeAPIKey), !key.isEmpty else {
            return ""
        }
        // Show first 8 and last 4 characters
        if key.count > 12 {
            let prefix = String(key.prefix(8))
            let suffix = String(key.suffix(4))
            return "\(prefix)...\(suffix)"
        }
        return key
    }

    // MARK: - Initialization

    private init() {
        // Load saved preferences
        if let providerRaw = userDefaults.string(forKey: DefaultsKey.modelProvider),
           let provider = AIModelProvider(rawValue: providerRaw) {
            self.selectedProvider = provider
        } else {
            self.selectedProvider = .openAI
        }

        if let modelRaw = userDefaults.string(forKey: DefaultsKey.openAIModel),
           let model = OpenAIModel(rawValue: modelRaw) {
            self.selectedOpenAIModel = model
        } else {
            self.selectedOpenAIModel = .gpt5
        }

        if let modelRaw = userDefaults.string(forKey: DefaultsKey.claudeModel),
           let model = ClaudeModel(rawValue: modelRaw) {
            self.selectedClaudeModel = model
        } else {
            self.selectedClaudeModel = .claude45Sonnet
        }
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

    func getOpenAIKey() -> String? {
        try? keychain.retrieve(.openAIAPIKey)
    }

    func getClaudeKey() -> String? {
        try? keychain.retrieve(.claudeAPIKey)
    }

    func deleteOpenAIKey() throws {
        try keychain.delete(.openAIAPIKey)
    }

    func deleteClaudeKey() throws {
        try keychain.delete(.claudeAPIKey)
    }
}
