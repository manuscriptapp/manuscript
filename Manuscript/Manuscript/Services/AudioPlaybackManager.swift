import Foundation
import AVFoundation
import SwiftUI

/// Observable manager for audio playback of TTS content
@MainActor
@Observable
final class AudioPlaybackManager: NSObject {
    static let shared = AudioPlaybackManager()

    private var audioPlayer: AVAudioPlayer?
    private let elevenLabsService = ElevenLabsService.shared
    private let settingsManager = ElevenLabsSettingsManager.shared
    private var currentTask: Task<Void, Never>?
    private var isCancelled: Bool = false

    // MARK: - Published Properties

    private(set) var isPlaying: Bool = false
    private(set) var isPaused: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var error: String?

    // Progress tracking
    private(set) var downloadProgress: DownloadProgress?
    private(set) var wordCount: Int = 0
    private(set) var characterCount: Int = 0

    // MARK: - Playback State

    enum PlaybackState {
        case idle
        case loading
        case playing
        case paused
        case error
    }

    var state: PlaybackState {
        if isLoading { return .loading }
        if error != nil { return .error }
        if isPaused { return .paused }
        if isPlaying { return .playing }
        return .idle
    }

    // MARK: - Computed Properties

    var canSpeak: Bool {
        settingsManager.isConfigured && !isLoading
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        setupAudioSession()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }

    // MARK: - Playback Controls

    /// Generate and play speech from text
    func speak(text: String) async {
        guard let voiceId = settingsManager.selectedVoiceId else {
            error = "No voice selected"
            return
        }

        // Don't start if already loading
        guard !isLoading else { return }

        // Stop any current playback and cancel pending tasks
        stop()
        isCancelled = false

        // Track text stats
        wordCount = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        characterCount = text.count
        downloadProgress = nil

        isLoading = true
        error = nil

        do {
            let audioData = try await elevenLabsService.generateSpeech(
                text: text,
                voiceId: voiceId
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress
                }
            }

            // Check if cancelled while loading
            guard !isCancelled else {
                isLoading = false
                downloadProgress = nil
                return
            }

            // Create audio player from data
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            isLoading = false
            isPlaying = true
            isPaused = false

            audioPlayer?.play()
        } catch {
            if !isCancelled {
                isLoading = false
                self.error = error.localizedDescription
            }
        }
    }

    /// Cancel the current loading operation
    func cancel() {
        isCancelled = true
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
        error = nil
    }

    /// Stop playback
    func stop() {
        cancel()
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isPaused = false
    }

    /// Pause playback
    func pause() {
        guard isPlaying, !isPaused else { return }
        audioPlayer?.pause()
        isPaused = true
    }

    /// Resume playback
    func resume() {
        guard isPaused else { return }
        audioPlayer?.play()
        isPaused = false
    }

    /// Toggle between play and pause
    func togglePlayPause() {
        if isPaused {
            resume()
        } else if isPlaying {
            pause()
        }
    }

    /// Clear any error state
    func clearError() {
        error = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            isPaused = false
            audioPlayer = nil
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        Task { @MainActor in
            self.error = error?.localizedDescription ?? "Audio decode error"
            isPlaying = false
            isPaused = false
            audioPlayer = nil
        }
    }
}
