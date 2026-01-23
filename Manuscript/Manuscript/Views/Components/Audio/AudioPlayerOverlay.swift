import SwiftUI
import AVFoundation
import Combine

/// Popover view for text-to-speech controls and settings
struct AudioPlayerPopover: View {
    @State private var audioPlayback = AudioPlaybackManager.shared
    @State private var elevenLabsSettings = ElevenLabsSettingsManager.shared
    @Binding var isPresented: Bool

    /// The text to be read aloud
    let text: String

    /// Whether reading selected text (true) or full document (false)
    var isSelection: Bool = false

    /// Computed word count for the text
    private var wordCount: Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    /// Computed character count
    private var characterCount: Int {
        text.count
    }

    /// Estimated audio size based on word count
    private var estimatedAudioSize: String {
        let estimatedBytes = Int64(wordCount * 6500)
        return ByteCountFormatter.string(fromByteCount: estimatedBytes, countStyle: .file)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with status and controls
            headerSection
                .padding()

            Divider()

            // Text info and progress
            VStack(spacing: 12) {
                textInfoSection

                if audioPlayback.state == .loading {
                    downloadProgressView
                }
            }
            .padding()

            Divider()

            // Voice and settings
            VStack(spacing: 12) {
                voicePicker
                voiceSettings
            }
            .padding()

            Divider()

            // Footer
            footerSection
                .padding()
        }
        .frame(width: 320)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Status icon and text
            HStack(spacing: 10) {
                statusIcon
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.headline)

                    if let subtitle = statusSubtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Playback controls
            playbackControls
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch audioPlayback.state {
        case .idle:
            Image(systemName: "speaker.wave.2")
                .font(.title2)
                .foregroundStyle(.secondary)
        case .loading:
            LoadingWaveform()
        case .playing:
            PlayingWaveform()
        case .paused:
            Image(systemName: "pause.circle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.red)
        }
    }

    private var statusTitle: String {
        switch audioPlayback.state {
        case .idle: return "Ready"
        case .loading: return "Generating..."
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .error: return "Error"
        }
    }

    private var statusSubtitle: String? {
        switch audioPlayback.state {
        case .error:
            return audioPlayback.error
        case .loading, .playing, .paused:
            return elevenLabsSettings.selectedVoiceName
        default:
            return nil
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 12) {
            switch audioPlayback.state {
            case .idle, .error:
                // Play button
                Button {
                    Task {
                        await audioPlayback.speak(text: text)
                    }
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .disabled(!elevenLabsSettings.isConfigured || text.isEmpty)

            case .loading:
                // Cancel button
                Button {
                    audioPlayback.cancel()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)

            case .playing:
                // Pause button
                Button {
                    audioPlayback.pause()
                } label: {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                // Stop button
                Button {
                    audioPlayback.stop()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

            case .paused:
                // Resume button
                Button {
                    audioPlayback.resume()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                // Stop button
                Button {
                    audioPlayback.stop()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Text Info Section

    private var textInfoSection: some View {
        HStack {
            // Source badge
            HStack(spacing: 6) {
                Image(systemName: isSelection ? "text.cursor" : "doc.text")
                Text(isSelection ? "Selection" : "Document")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(isSelection ? .white : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelection ? Color.blue : Color.secondary.opacity(0.2))
            .clipShape(Capsule())

            Spacer()

            // Stats
            HStack(spacing: 12) {
                Label("\(wordCount)", systemImage: "text.word.spacing")
                Text("\(characterCount) chars")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
    }

    // MARK: - Download Progress

    @ViewBuilder
    private var downloadProgressView: some View {
        VStack(spacing: 8) {
            // Progress bar
            if let progress = audioPlayback.downloadProgress {
                ProgressView(value: progress.progressFraction ?? 0)
                    .progressViewStyle(.linear)

                HStack {
                    // Size info
                    if let expected = progress.formattedExpectedBytes {
                        Text("\(progress.formattedBytesReceived) / \(expected)")
                    } else {
                        Text("\(progress.formattedBytesReceived) / ~\(estimatedAudioSize)")
                    }

                    Spacer()

                    // Speed and time
                    Text("\(progress.formattedSpeed)")
                    Text("(\(formatTime(progress.elapsedTime)))")
                        .foregroundStyle(.tertiary)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Connecting to ElevenLabs...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        if seconds < 60 {
            return "\(seconds)s"
        }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Voice Picker

    private var voicePicker: some View {
        HStack {
            Text("Voice")
                .font(.subheadline.weight(.medium))
            Spacer()
            Picker("", selection: Binding(
                get: { elevenLabsSettings.selectedVoiceId ?? "" },
                set: { newId in
                    if let voice = elevenLabsSettings.cachedVoices.first(where: { $0.voiceId == newId }) {
                        elevenLabsSettings.selectVoice(voice)
                    }
                }
            )) {
                ForEach(elevenLabsSettings.cachedVoices) { voice in
                    Text(voice.name).tag(voice.voiceId)
                }
            }
            .labelsHidden()
            #if os(iOS)
            .pickerStyle(.menu)
            #endif
        }
    }

    // MARK: - Voice Settings

    private var voiceSettings: some View {
        VStack(spacing: 10) {
            settingSlider(title: "Stability", value: $elevenLabsSettings.stability)
            settingSlider(title: "Clarity", value: $elevenLabsSettings.similarityBoost)
            settingSlider(title: "Style", value: $elevenLabsSettings.style)

            Toggle("Speaker Boost", isOn: $elevenLabsSettings.useSpeakerBoost)
                .font(.caption)
        }
    }

    private func settingSlider(title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .frame(width: 55, alignment: .leading)

            Slider(value: value, in: 0...1, step: 0.05)
                .controlSize(.small)

            Text("\(Int(value.wrappedValue * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 36, alignment: .trailing)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Link(destination: URL(string: "https://elevenlabs.io/voice-library")!) {
                Label("Voice Library", systemImage: "globe")
                    .font(.caption)
            }

            Spacer()

            Text("~\(estimatedAudioSize) estimated")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Loading Waveform Animation

struct LoadingWaveform: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(Color.blue)
                    .frame(width: 4)
                    .scaleEffect(y: animating ? 1.0 : 0.3, anchor: .center)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - Playing Waveform Animation

struct PlayingWaveform: View {
    @State private var heights: [CGFloat] = [0.5, 0.5, 0.5]
    let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(Color.green)
                    .frame(width: 4)
                    .scaleEffect(y: heights[index], anchor: .center)
                    .animation(.easeInOut(duration: 0.15), value: heights[index])
            }
        }
        .onReceive(timer) { _ in
            heights = heights.map { _ in CGFloat.random(in: 0.3...1.0) }
        }
    }
}

#Preview {
    AudioPlayerPopover(
        isPresented: .constant(true),
        text: "This is a test with some words to count for the preview.",
        isSelection: true
    )
}
