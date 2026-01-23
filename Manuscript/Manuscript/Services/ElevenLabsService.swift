import Foundation

// MARK: - Download Progress

struct DownloadProgress {
    let bytesReceived: Int64
    let expectedBytes: Int64?
    let bytesPerSecond: Double
    let elapsedTime: TimeInterval

    var formattedBytesReceived: String {
        ByteCountFormatter.string(fromByteCount: bytesReceived, countStyle: .file)
    }

    var formattedExpectedBytes: String? {
        guard let expected = expectedBytes else { return nil }
        return ByteCountFormatter.string(fromByteCount: expected, countStyle: .file)
    }

    var formattedSpeed: String {
        let speed = Int64(bytesPerSecond)
        return ByteCountFormatter.string(fromByteCount: speed, countStyle: .file) + "/s"
    }

    var progressFraction: Double? {
        guard let expected = expectedBytes, expected > 0 else { return nil }
        return Double(bytesReceived) / Double(expected)
    }
}

/// Actor for ElevenLabs API communication
actor ElevenLabsService {
    static let shared = ElevenLabsService()

    private let baseURL = "https://api.elevenlabs.io/v1"
    private let settingsManager = ElevenLabsSettingsManager.shared

    enum ElevenLabsError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case httpError(Int, String?)
        case decodingError(Error)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "ElevenLabs API key not configured"
            case .invalidResponse:
                return "Invalid response from ElevenLabs API"
            case .httpError(let code, let message):
                if let message = message {
                    return "HTTP \(code): \(message)"
                }
                return "HTTP error: \(code)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }

    private init() {}

    // MARK: - API Methods

    /// Fetch available voices from ElevenLabs
    @MainActor
    func fetchVoices() async throws -> [ElevenLabsVoice] {
        guard let apiKey = settingsManager.getAPIKey() else {
            throw ElevenLabsError.noAPIKey
        }

        let url = URL(string: "\(baseURL)/voices")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorMessage = try? JSONDecoder().decode(ElevenLabsErrorResponse.self, from: data)
                throw ElevenLabsError.httpError(httpResponse.statusCode, errorMessage?.detail?.message)
            }

            let voicesResponse = try JSONDecoder().decode(ElevenLabsVoicesResponse.self, from: data)

            // Cache the voices
            settingsManager.setCachedVoices(voicesResponse.voices)

            return voicesResponse.voices
        } catch let error as ElevenLabsError {
            throw error
        } catch let error as DecodingError {
            throw ElevenLabsError.decodingError(error)
        } catch {
            throw ElevenLabsError.networkError(error)
        }
    }

    /// Generate speech from text using ElevenLabs with progress updates
    @MainActor
    func generateSpeech(
        text: String,
        voiceId: String,
        onProgress: ((DownloadProgress) -> Void)? = nil
    ) async throws -> Data {
        guard let apiKey = settingsManager.getAPIKey() else {
            throw ElevenLabsError.noAPIKey
        }

        let url = URL(string: "\(baseURL)/text-to-speech/\(voiceId)/stream")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ElevenLabsSpeechRequest(
            text: text,
            modelId: "eleven_multilingual_v2",
            voiceSettings: ElevenLabsVoiceSettings(
                stability: settingsManager.stability,
                similarityBoost: settingsManager.similarityBoost,
                style: settingsManager.style,
                useSpeakerBoost: settingsManager.useSpeakerBoost
            )
        )

        request.httpBody = try JSONEncoder().encode(body)

        let startTime = Date()

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                // For error responses, collect all data to get error message
                var errorData = Data()
                for try await byte in bytes {
                    errorData.append(byte)
                }
                let errorMessage = try? JSONDecoder().decode(ElevenLabsErrorResponse.self, from: errorData)
                throw ElevenLabsError.httpError(httpResponse.statusCode, errorMessage?.detail?.message)
            }

            // Get expected content length if available
            let expectedLength = httpResponse.expectedContentLength

            var audioData = Data()
            var lastProgressUpdate = startTime

            for try await byte in bytes {
                audioData.append(byte)

                // Update progress every 100ms or every 10KB
                let now = Date()
                if now.timeIntervalSince(lastProgressUpdate) >= 0.1 || audioData.count % 10240 == 0 {
                    let elapsed = now.timeIntervalSince(startTime)
                    let bytesPerSecond = elapsed > 0 ? Double(audioData.count) / elapsed : 0

                    let progress = DownloadProgress(
                        bytesReceived: Int64(audioData.count),
                        expectedBytes: expectedLength > 0 ? expectedLength : nil,
                        bytesPerSecond: bytesPerSecond,
                        elapsedTime: elapsed
                    )
                    onProgress?(progress)
                    lastProgressUpdate = now
                }
            }

            // Final progress update
            let elapsed = Date().timeIntervalSince(startTime)
            let finalProgress = DownloadProgress(
                bytesReceived: Int64(audioData.count),
                expectedBytes: Int64(audioData.count),
                bytesPerSecond: elapsed > 0 ? Double(audioData.count) / elapsed : 0,
                elapsedTime: elapsed
            )
            onProgress?(finalProgress)

            return audioData
        } catch let error as ElevenLabsError {
            throw error
        } catch {
            throw ElevenLabsError.networkError(error)
        }
    }

    /// Test the API connection
    @MainActor
    func testConnection() async throws -> Bool {
        _ = try await fetchVoices()
        return true
    }
}

// MARK: - Request/Response Models

private struct ElevenLabsSpeechRequest: Codable {
    let text: String
    let modelId: String
    let voiceSettings: ElevenLabsVoiceSettings

    enum CodingKeys: String, CodingKey {
        case text
        case modelId = "model_id"
        case voiceSettings = "voice_settings"
    }
}

private struct ElevenLabsVoiceSettings: Codable {
    let stability: Double
    let similarityBoost: Double
    let style: Double
    let useSpeakerBoost: Bool

    enum CodingKeys: String, CodingKey {
        case stability
        case similarityBoost = "similarity_boost"
        case style
        case useSpeakerBoost = "use_speaker_boost"
    }
}

private struct ElevenLabsErrorResponse: Codable {
    let detail: ElevenLabsErrorDetail?
}

private struct ElevenLabsErrorDetail: Codable {
    let status: String?
    let message: String?
}
