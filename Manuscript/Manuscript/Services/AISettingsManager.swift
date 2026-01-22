import Foundation
import SwiftUI

/// Model provider options for AI text generation
enum AIModelProvider: String, CaseIterable, Identifiable {
    case auto = "auto"
    case openAI = "openai"
    case claude = "claude"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto:
            return "Auto (Manuscript Server)"
        case .openAI:
            return "OpenAI"
        case .claude:
            return "Claude (Anthropic)"
        }
    }

    var description: String {
        switch self {
        case .auto:
            return "Uses Manuscript's server for AI features. No API key required."
        case .openAI:
            return "Use your own OpenAI API key for direct access."
        case .claude:
            return "Use your own Claude API key for direct access."
        }
    }
}

/// Available OpenAI models
enum OpenAIModel: String, CaseIterable, Identifiable {
    case gpt4o = "gpt-4o"
    case gpt4oMini = "gpt-4o-mini"
    case gpt4Turbo = "gpt-4-turbo"
    case gpt4 = "gpt-4"
    case gpt35Turbo = "gpt-3.5-turbo"
    case o1 = "o1"
    case o1Mini = "o1-mini"
    case o1Pro = "o1-pro"
    case o3Mini = "o3-mini"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gpt4o:
            return "GPT-4o (Recommended)"
        case .gpt4oMini:
            return "GPT-4o Mini (Fast & Affordable)"
        case .gpt4Turbo:
            return "GPT-4 Turbo"
        case .gpt4:
            return "GPT-4"
        case .gpt35Turbo:
            return "GPT-3.5 Turbo (Budget)"
        case .o1:
            return "o1 (Reasoning)"
        case .o1Mini:
            return "o1-mini (Fast Reasoning)"
        case .o1Pro:
            return "o1-pro (Advanced Reasoning)"
        case .o3Mini:
            return "o3-mini (Latest Reasoning)"
        }
    }

    var description: String {
        switch self {
        case .gpt4o:
            return "Most capable model, great for creative writing"
        case .gpt4oMini:
            return "Fast responses, lower cost"
        case .gpt4Turbo:
            return "Previous flagship model"
        case .gpt4:
            return "Original GPT-4"
        case .gpt35Turbo:
            return "Good for simple tasks, very affordable"
        case .o1:
            return "Advanced reasoning capabilities"
        case .o1Mini:
            return "Faster reasoning model"
        case .o1Pro:
            return "Most advanced reasoning"
        case .o3Mini:
            return "Latest compact reasoning model"
        }
    }
}

/// Available Claude models
enum ClaudeModel: String, CaseIterable, Identifiable {
    case claude4Opus = "claude-opus-4-20250514"
    case claude4Sonnet = "claude-sonnet-4-20250514"
    case claude35Sonnet = "claude-3-5-sonnet-20241022"
    case claude35Haiku = "claude-3-5-haiku-20241022"
    case claude3Opus = "claude-3-opus-20240229"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude4Opus:
            return "Claude 4 Opus (Most Capable)"
        case .claude4Sonnet:
            return "Claude 4 Sonnet (Recommended)"
        case .claude35Sonnet:
            return "Claude 3.5 Sonnet"
        case .claude35Haiku:
            return "Claude 3.5 Haiku (Fast)"
        case .claude3Opus:
            return "Claude 3 Opus"
        }
    }

    var description: String {
        switch self {
        case .claude4Opus:
            return "Most intelligent, best for complex creative writing"
        case .claude4Sonnet:
            return "Excellent balance of speed and capability"
        case .claude35Sonnet:
            return "Great all-around model"
        case .claude35Haiku:
            return "Fast responses, lower cost"
        case .claude3Opus:
            return "Previous generation flagship"
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
            self.selectedProvider = .auto
        }

        if let modelRaw = userDefaults.string(forKey: DefaultsKey.openAIModel),
           let model = OpenAIModel(rawValue: modelRaw) {
            self.selectedOpenAIModel = model
        } else {
            self.selectedOpenAIModel = .gpt4o
        }

        if let modelRaw = userDefaults.string(forKey: DefaultsKey.claudeModel),
           let model = ClaudeModel(rawValue: modelRaw) {
            self.selectedClaudeModel = model
        } else {
            self.selectedClaudeModel = .claude4Sonnet
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
