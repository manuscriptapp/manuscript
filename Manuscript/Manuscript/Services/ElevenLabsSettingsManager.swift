import Foundation
import SwiftUI

/// Voice model from ElevenLabs API
struct ElevenLabsVoice: Codable, Identifiable, Hashable {
    let voiceId: String
    let name: String
    let labels: [String: String]?

    var id: String { voiceId }

    /// Check if this voice supports Swedish
    var supportsSwedish: Bool {
        guard let labels = labels else { return false }
        let language = labels["language"] ?? ""
        return language.lowercased().contains("swedish") ||
               language.lowercased().contains("multilingual")
    }

    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case name
        case labels
    }
}

/// Response from ElevenLabs voices endpoint
struct ElevenLabsVoicesResponse: Codable {
    let voices: [ElevenLabsVoice]
}

/// Observable manager for ElevenLabs TTS settings
@MainActor
@Observable
final class ElevenLabsSettingsManager {
    static let shared = ElevenLabsSettingsManager()

    private let keychain = KeychainService.shared
    private let userDefaults = UserDefaults.standard

    // Keys for UserDefaults
    private enum DefaultsKey {
        static let selectedVoiceId = "elevenlabs_selected_voice_id"
        static let selectedVoiceName = "elevenlabs_selected_voice_name"
        static let cachedVoices = "elevenlabs_cached_voices"
        static let stability = "elevenlabs_stability"
        static let similarityBoost = "elevenlabs_similarity_boost"
        static let style = "elevenlabs_style"
        static let useSpeakerBoost = "elevenlabs_use_speaker_boost"
    }

    // MARK: - Published Properties

    var selectedVoiceId: String? {
        didSet {
            if let id = selectedVoiceId {
                userDefaults.set(id, forKey: DefaultsKey.selectedVoiceId)
            } else {
                userDefaults.removeObject(forKey: DefaultsKey.selectedVoiceId)
            }
        }
    }

    var selectedVoiceName: String? {
        didSet {
            if let name = selectedVoiceName {
                userDefaults.set(name, forKey: DefaultsKey.selectedVoiceName)
            } else {
                userDefaults.removeObject(forKey: DefaultsKey.selectedVoiceName)
            }
        }
    }

    var cachedVoices: [ElevenLabsVoice] = []

    // MARK: - Voice Settings

    /// Stability: 0 = more variable/expressive, 1 = more consistent (default: 0.5)
    var stability: Double {
        didSet {
            userDefaults.set(stability, forKey: DefaultsKey.stability)
        }
    }

    /// Similarity Boost: How closely to match the original voice (default: 0.75)
    var similarityBoost: Double {
        didSet {
            userDefaults.set(similarityBoost, forKey: DefaultsKey.similarityBoost)
        }
    }

    /// Style: Style exaggeration, 0 = none, 1 = max (default: 0.0). Higher values use more compute.
    var style: Double {
        didSet {
            userDefaults.set(style, forKey: DefaultsKey.style)
        }
    }

    /// Speaker Boost: Enhances similarity to original speaker (default: true)
    var useSpeakerBoost: Bool {
        didSet {
            userDefaults.set(useSpeakerBoost, forKey: DefaultsKey.useSpeakerBoost)
        }
    }

    // MARK: - Computed Properties

    var hasAPIKey: Bool {
        keychain.exists(.elevenLabsAPIKey)
    }

    var apiKeyPreview: String {
        guard let key = try? keychain.retrieve(.elevenLabsAPIKey), !key.isEmpty else {
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

    var isConfigured: Bool {
        hasAPIKey && selectedVoiceId != nil
    }

    // MARK: - Initialization

    private init() {
        // Load saved preferences
        self.selectedVoiceId = userDefaults.string(forKey: DefaultsKey.selectedVoiceId)
        self.selectedVoiceName = userDefaults.string(forKey: DefaultsKey.selectedVoiceName)

        // Load voice settings with defaults optimized for audiobook narration
        self.stability = userDefaults.object(forKey: DefaultsKey.stability) as? Double ?? 0.70
        self.similarityBoost = userDefaults.object(forKey: DefaultsKey.similarityBoost) as? Double ?? 0.70
        self.style = userDefaults.object(forKey: DefaultsKey.style) as? Double ?? 0.25
        self.useSpeakerBoost = userDefaults.object(forKey: DefaultsKey.useSpeakerBoost) as? Bool ?? true

        // Load cached voices from UserDefaults
        if let data = userDefaults.data(forKey: DefaultsKey.cachedVoices),
           let voices = try? JSONDecoder().decode([ElevenLabsVoice].self, from: data) {
            self.cachedVoices = voices
        }
    }

    // MARK: - API Key Management

    func saveAPIKey(_ key: String) throws {
        if key.isEmpty {
            try keychain.delete(.elevenLabsAPIKey)
        } else {
            try keychain.save(key, for: .elevenLabsAPIKey)
        }
    }

    func getAPIKey() -> String? {
        try? keychain.retrieve(.elevenLabsAPIKey)
    }

    func deleteAPIKey() throws {
        try keychain.delete(.elevenLabsAPIKey)
        selectedVoiceId = nil
        selectedVoiceName = nil
        cachedVoices = []
        userDefaults.removeObject(forKey: DefaultsKey.cachedVoices)
    }

    // MARK: - Voice Management

    func setCachedVoices(_ voices: [ElevenLabsVoice]) {
        cachedVoices = voices
        // Cache to UserDefaults
        if let data = try? JSONEncoder().encode(voices) {
            userDefaults.set(data, forKey: DefaultsKey.cachedVoices)
        }
    }

    func selectVoice(_ voice: ElevenLabsVoice) {
        selectedVoiceId = voice.voiceId
        selectedVoiceName = voice.name
    }

    /// Auto-select a Swedish voice if available, otherwise select the first voice
    func autoSelectVoice(from voices: [ElevenLabsVoice]) {
        // First, try to find a Swedish voice
        if let swedishVoice = voices.first(where: { $0.supportsSwedish }) {
            selectVoice(swedishVoice)
            return
        }
        // Otherwise, select the first available voice
        if let firstVoice = voices.first {
            selectVoice(firstVoice)
        }
    }
}
