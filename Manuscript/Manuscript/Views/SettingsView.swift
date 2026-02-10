import SwiftUI
import AVFoundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case format = "Format"
    case ai = "AI"
    case speech = "Speech"
    case backups = "Backups"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gear"
        case .format: return "textformat"
        case .ai: return "brain"
        case .speech: return "speaker.wave.2"
        case .backups: return "externaldrive"
        }
    }
}

struct SettingsView: View {
    @AppStorage("defaultAuthorName") private var defaultAuthorName: String = ""
    @State private var aiSettings = AISettingsManager.shared
    @State private var elevenLabsSettings = ElevenLabsSettingsManager.shared
    @State private var selectedTab: SettingsTab = .general
    @EnvironmentObject private var backupManager: BackupManager
    @Environment(ThemeManager.self) private var themeManager

    // Formatting defaults
    @AppStorage("defaultFontName") private var defaultFontName: String = "Palatino"
    @AppStorage("defaultFontSize") private var defaultFontSize: Double = 16
    @AppStorage("defaultLineSpacing") private var defaultLineSpacing: String = "single"
    @AppStorage("enableParagraphIndent") private var enableParagraphIndent: Bool = true
    @AppStorage("paragraphIndentSize") private var paragraphIndentSize: Double = 24

    // API Key input states
    @State private var openAIKeyInput: String = ""
    @State private var claudeKeyInput: String = ""
    @State private var elevenLabsKeyInput: String = ""
    @State private var showOpenAIKey: Bool = false
    @State private var showClaudeKey: Bool = false
    @State private var showElevenLabsKey: Bool = false

    // Connection test states
    @State private var isTestingOpenAI: Bool = false
    @State private var isTestingClaude: Bool = false
    @State private var isTestingElevenLabs: Bool = false
    @State private var openAITestResult: TestResult?
    @State private var claudeTestResult: TestResult?
    @State private var elevenLabsTestResult: TestResult?

    // ElevenLabs voice loading state
    @State private var isLoadingVoices: Bool = false
    @State private var isPreviewingVoice: Bool = false
    @State private var previewAudioPlayer: AVAudioPlayer?
    @State private var backupToDelete: BackupRecord?

    enum TestResult {
        case success
        case failure(String)
    }

    private let fontSizes = [10, 12, 14, 16, 18, 20, 24, 28, 32, 36]
    private let lineSpacingOptions = [
        ("Single", "single"),
        ("1.15", "1.15"),
        ("1.5", "1.5"),
        ("Double", "double")
    ]
    private let indentSizeOptions = [12, 18, 24, 30, 36, 48]
    private let backupIntervalOptions: [Double] = [5, 15, 30, 60, 120, 240, 720]

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var themeSelection: Binding<String> {
        Binding(
            get: { themeManager.selectedThemeID },
            set: { themeManager.selectedThemeID = $0 }
        )
    }

    var body: some View {
        #if os(macOS)
        TabView(selection: $selectedTab) {
            generalTabContent
                .tabItem {
                    Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.icon)
                }
                .tag(SettingsTab.general)

            formatTabContent
                .tabItem {
                    Label(SettingsTab.format.rawValue, systemImage: SettingsTab.format.icon)
                }
                .tag(SettingsTab.format)

            aiTabContent
                .tabItem {
                    Label(SettingsTab.ai.rawValue, systemImage: SettingsTab.ai.icon)
                }
                .tag(SettingsTab.ai)

            speechTabContent
                .tabItem {
                    Label(SettingsTab.speech.rawValue, systemImage: SettingsTab.speech.icon)
                }
                .tag(SettingsTab.speech)

            backupTabContent
                .tabItem {
                    Label(SettingsTab.backups.rawValue, systemImage: SettingsTab.backups.icon)
                }
                .tag(SettingsTab.backups)
        }
        .frame(minWidth: 450, minHeight: 400)
        .onAppear {
            loadExistingKeys()
            backupManager.refreshBackupsList()
        }
        #else
        NavigationStack {
            List {
                ForEach(SettingsTab.allCases) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsTab.self) { tab in
                settingsContent(for: tab)
            }
        }
        .onAppear {
            loadExistingKeys()
            backupManager.refreshBackupsList()
        }
        #endif
    }

    // MARK: - Tab Content Views

    #if os(macOS)
    @ViewBuilder
    private var generalTabContent: some View {
        Form {
            Section("Author") {
                TextField("Name", text: $defaultAuthorName, prompt: Text("Enter default author name"))
            }

            appearanceSection

            Section("About") {
                LabeledContent("Version", value: appVersion)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var formatTabContent: some View {
        Form {
            formattingSection
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var aiTabContent: some View {
        Form {
            aiSettingsSection
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var speechTabContent: some View {
        Form {
            ttsSettingsSection
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var backupTabContent: some View {
        Form {
            backupSettingsSection
        }
        .formStyle(.grouped)
    }
    #endif

    // MARK: - iOS Navigation Content

    #if os(iOS)
    @ViewBuilder
    private func settingsContent(for tab: SettingsTab) -> some View {
        Form {
            switch tab {
            case .general:
                Section("Author") {
                    TextField("Name", text: $defaultAuthorName, prompt: Text("Enter default author name"))
                        .textInputAutocapitalization(.words)
                }

                appearanceSection

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }

            case .format:
                formattingSection

            case .ai:
                aiSettingsSection

            case .speech:
                ttsSettingsSection

            case .backups:
                backupSettingsSection
            }
        }
        .navigationTitle(tab.rawValue)
    }
    #endif

    @ViewBuilder
    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: themeSelection) {
                ForEach(themeManager.themes) { theme in
                    Text(theme.name).tag(theme.id)
                }
            }

            Button("Reload Themes") {
                themeManager.reloadThemes()
            }

            #if os(macOS)
            Button("Open Themes Folder") {
                NSWorkspace.shared.open(themeManager.themesDirectoryURL)
            }
            #endif

            Text("Themes folder: \(themeManager.themesDirectoryURL.path)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var formattingSection: some View {
        Section("Formatting") {
            Picker("Font", selection: $defaultFontName) {
                ForEach(availableFonts, id: \.self) { fontName in
                    Text(fontName).tag(fontName)
                }
            }

            Picker("Size", selection: Binding(
                get: { Int(defaultFontSize) },
                set: { defaultFontSize = Double($0) }
            )) {
                ForEach(fontSizes, id: \.self) { size in
                    Text("\(size) pt").tag(size)
                }
            }

            Picker("Line Spacing", selection: $defaultLineSpacing) {
                ForEach(lineSpacingOptions, id: \.1) { option in
                    Text(option.0).tag(option.1)
                }
            }

            Toggle("First Line Indent", isOn: $enableParagraphIndent)

            if enableParagraphIndent {
                Picker("Indent Size", selection: Binding(
                    get: { Int(paragraphIndentSize) },
                    set: { paragraphIndentSize = Double($0) }
                )) {
                    ForEach(indentSizeOptions, id: \.self) { size in
                        Text("\(size) pt").tag(size)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var backupSettingsSection: some View {
        Section("Automatic Backups") {
            Toggle("Enable automatic backups", isOn: $backupManager.isAutoBackupEnabled)

            Picker("Backup frequency", selection: $backupManager.backupIntervalMinutes) {
                ForEach(backupIntervalOptions, id: \.self) { minutes in
                    if minutes >= 60 {
                        Text(String(format: "%.0f hours", minutes / 60)).tag(minutes)
                    } else {
                        Text(String(format: "%.0f minutes", minutes)).tag(minutes)
                    }
                }
            }

            Stepper(value: $backupManager.maxBackupsPerDocument, in: 1...50) {
                Text("Keep \(backupManager.maxBackupsPerDocument) backups per manuscript")
            }

            if !backupManager.isDocumentReady {
                Text("Save your manuscript to enable backups.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Manual Backup") {
            Button {
                backupManager.performManualBackup()
            } label: {
                if backupManager.isBackupInProgress {
                    Label("Backing up…", systemImage: "arrow.triangle.2.circlepath")
                } else {
                    Label("Back Up Now", systemImage: "externaldrive.badge.plus")
                }
            }
            .disabled(!backupManager.isDocumentReady || backupManager.isBackupInProgress)

            if let lastBackupDate = backupManager.lastBackupDate {
                LabeledContent("Last backup", value: formattedDate(lastBackupDate))
            }

            if let error = backupManager.lastBackupError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }

        Section("Recent Backups") {
            if backupManager.backups.isEmpty {
                Text("No backups yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(backupManager.backups.prefix(10)) { backup in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(backup.documentTitle.isEmpty ? "Untitled Manuscript" : backup.documentTitle)
                            .font(.headline)
                        Text(formattedDate(backup.createdAt))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(formattedSize(backup.sizeBytes))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            backupToDelete = backup
                        } label: {
                            Label("Delete Backup", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .alert("Delete Backup?", isPresented: Binding<Bool>(
            get: { backupToDelete != nil },
            set: { if !$0 { backupToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { backupToDelete = nil }
            Button("Delete", role: .destructive) {
                if let backup = backupToDelete {
                    backupManager.deleteBackup(backup)
                }
                backupToDelete = nil
            }
        } message: {
            Text("This backup will be permanently removed.")
        }

        if let backupRootPath = backupManager.backupRootPath {
            Section("Backup Location") {
                Text(backupRootPath)
                    .font(.footnote)
                    .textSelection(.enabled)
                #if os(macOS)
                Button("Reveal in Finder") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: backupRootPath))
                }
                #endif
            }
        }
    }

    private var availableFonts: [String] {
        let commonFonts = ["Palatino", "Georgia", "Times New Roman", "Helvetica", "Arial", "Courier New", "Menlo"]
        #if os(macOS)
        let allFonts = NSFontManager.shared.availableFontFamilies.sorted()
        #else
        let allFonts = UIFont.familyNames.sorted()
        #endif

        var result: [String] = []
        for font in commonFonts {
            if allFonts.contains(font) {
                result.append(font)
            }
        }
        for font in allFonts {
            if !result.contains(font) {
                result.append(font)
            }
        }
        return result
    }

    @ViewBuilder
    private var aiSettingsSection: some View {
        Section("AI Provider") {
            Picker("Provider", selection: $aiSettings.selectedProvider) {
                ForEach(AIModelProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            Text(aiSettings.selectedProvider.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if aiSettings.selectedProvider == .openAI {
            Section("OpenAI") {
                openAIKeyField

                Picker("Model", selection: $aiSettings.selectedOpenAIModel) {
                    ForEach(OpenAIModel.allCases) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif

                if aiSettings.hasOpenAIKey {
                    testConnectionButton(for: .openAI)
                }
            }
        }

        if aiSettings.selectedProvider == .claude {
            Section("Claude") {
                claudeKeyField

                Picker("Model", selection: $aiSettings.selectedClaudeModel) {
                    ForEach(ClaudeModel.allCases) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif

                if aiSettings.hasClaudeKey {
                    testConnectionButton(for: .claude)
                }
            }
        }
    }

    @ViewBuilder
    private var ttsSettingsSection: some View {
        Section {
            elevenLabsKeyField

            if elevenLabsSettings.hasAPIKey {
                HStack {
                    Picker("Voice", selection: Binding(
                        get: { elevenLabsSettings.selectedVoiceId ?? "" },
                        set: { newId in
                            if let voice = elevenLabsSettings.cachedVoices.first(where: { $0.voiceId == newId }) {
                                elevenLabsSettings.selectVoice(voice)
                            }
                        }
                    )) {
                        if elevenLabsSettings.cachedVoices.isEmpty {
                            Text("Load voices first").tag("")
                        } else {
                            ForEach(elevenLabsSettings.cachedVoices) { voice in
                                Text(voice.name).tag(voice.voiceId)
                            }
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.menu)
                    #endif

                    Button {
                        Task {
                            await loadVoices()
                        }
                    } label: {
                        if isLoadingVoices {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingVoices)
                }

                HStack {
                    Button {
                        Task {
                            await previewVoice()
                        }
                    } label: {
                        HStack {
                            if isPreviewingVoice {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text("Preview")
                        }
                    }
                    .disabled(isPreviewingVoice || elevenLabsSettings.selectedVoiceId == nil)

                    Spacer()

                    elevenLabsTestButton
                }
            }
        } header: {
            Text("Text-to-Speech")
        } footer: {
            Link("ElevenLabs Voice Library", destination: URL(string: "https://elevenlabs.io/voice-library")!)
                .font(.caption)
        }
    }

    @ViewBuilder
    private var elevenLabsTestButton: some View {
        Button {
            Task {
                await testElevenLabsConnection()
            }
        } label: {
            HStack {
                if isTestingElevenLabs {
                    ProgressView()
                        .controlSize(.small)
                    Text("Testing...")
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Test Connection")
                }
            }
        }
        .disabled(isTestingElevenLabs)

        if let result = elevenLabsTestResult {
            testResultView(result)
        }
    }

    @ViewBuilder
    private var elevenLabsKeyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if showElevenLabsKey {
                    TextField("API Key", text: $elevenLabsKeyInput)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                } else {
                    SecureField("API Key", text: $elevenLabsKeyInput)
                }

                Button {
                    showElevenLabsKey.toggle()
                } label: {
                    Image(systemName: showElevenLabsKey ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if elevenLabsSettings.hasAPIKey && elevenLabsKeyInput.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(elevenLabsSettings.apiKeyPreview)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Remove", role: .destructive) {
                        removeElevenLabsKey()
                    }
                    .font(.caption)
                }
            }

            if !elevenLabsKeyInput.isEmpty {
                Button("Save") {
                    saveElevenLabsKey()
                }
                .manuscriptPrimaryButton()
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var openAIKeyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if showOpenAIKey {
                    TextField("API Key", text: $openAIKeyInput)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                } else {
                    SecureField("API Key", text: $openAIKeyInput)
                }

                Button {
                    showOpenAIKey.toggle()
                } label: {
                    Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if aiSettings.hasOpenAIKey && openAIKeyInput.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(aiSettings.openAIKeyPreview)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Remove", role: .destructive) {
                        removeOpenAIKey()
                    }
                    .font(.caption)
                }
            }

            if !openAIKeyInput.isEmpty {
                Button("Save") {
                    saveOpenAIKey()
                }
                .manuscriptPrimaryButton()
                .controlSize(.small)
            }
        }

        if let result = openAITestResult {
            testResultView(result)
        }
    }

    @ViewBuilder
    private var claudeKeyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if showClaudeKey {
                    TextField("API Key", text: $claudeKeyInput)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                } else {
                    SecureField("API Key", text: $claudeKeyInput)
                }

                Button {
                    showClaudeKey.toggle()
                } label: {
                    Image(systemName: showClaudeKey ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if aiSettings.hasClaudeKey && claudeKeyInput.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(aiSettings.claudeKeyPreview)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Remove", role: .destructive) {
                        removeClaudeKey()
                    }
                    .font(.caption)
                }
            }

            if !claudeKeyInput.isEmpty {
                Button("Save") {
                    saveClaudeKey()
                }
                .manuscriptPrimaryButton()
                .controlSize(.small)
            }
        }

        if let result = claudeTestResult {
            testResultView(result)
        }
    }

    @ViewBuilder
    private func testConnectionButton(for provider: AIModelProvider) -> some View {
        Button {
            Task {
                await testConnection(for: provider)
            }
        } label: {
            HStack {
                if (provider == .openAI && isTestingOpenAI) || (provider == .claude && isTestingClaude) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Testing...")
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Test Connection")
                }
            }
        }
        .disabled((provider == .openAI && isTestingOpenAI) || (provider == .claude && isTestingClaude))
    }

    @ViewBuilder
    private func testResultView(_ result: TestResult) -> some View {
        HStack {
            switch result {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Connection successful!")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .failure(let message):
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func loadExistingKeys() {
        // Clear input fields - we show preview of saved keys separately
        openAIKeyInput = ""
        claudeKeyInput = ""
        elevenLabsKeyInput = ""
    }

    private func saveOpenAIKey() {
        do {
            try aiSettings.saveOpenAIKey(openAIKeyInput)
            openAIKeyInput = ""
            openAITestResult = nil
        } catch {
            openAITestResult = .failure("Failed to save key: \(error.localizedDescription)")
        }
    }

    private func saveClaudeKey() {
        do {
            try aiSettings.saveClaudeKey(claudeKeyInput)
            claudeKeyInput = ""
            claudeTestResult = nil
        } catch {
            claudeTestResult = .failure("Failed to save key: \(error.localizedDescription)")
        }
    }

    private func removeOpenAIKey() {
        do {
            try aiSettings.deleteOpenAIKey()
            openAIKeyInput = ""
            openAITestResult = nil
        } catch {
            openAITestResult = .failure("Failed to remove key: \(error.localizedDescription)")
        }
    }

    private func removeClaudeKey() {
        do {
            try aiSettings.deleteClaudeKey()
            claudeKeyInput = ""
            claudeTestResult = nil
        } catch {
            claudeTestResult = .failure("Failed to remove key: \(error.localizedDescription)")
        }
    }

    private func saveElevenLabsKey() {
        do {
            try elevenLabsSettings.saveAPIKey(elevenLabsKeyInput)
            elevenLabsKeyInput = ""
            elevenLabsTestResult = nil
            // Load voices after saving key
            Task {
                await loadVoices()
            }
        } catch {
            elevenLabsTestResult = .failure("Failed to save key: \(error.localizedDescription)")
        }
    }

    private func removeElevenLabsKey() {
        do {
            try elevenLabsSettings.deleteAPIKey()
            elevenLabsKeyInput = ""
            elevenLabsTestResult = nil
        } catch {
            elevenLabsTestResult = .failure("Failed to remove key: \(error.localizedDescription)")
        }
    }

    private func loadVoices() async {
        isLoadingVoices = true
        do {
            let voices = try await ElevenLabsService.shared.fetchVoices()
            // Auto-select a voice if none selected
            if elevenLabsSettings.selectedVoiceId == nil {
                elevenLabsSettings.autoSelectVoice(from: voices)
            }
        } catch {
            elevenLabsTestResult = .failure("Failed to load voices: \(error.localizedDescription)")
        }
        isLoadingVoices = false
    }

    private func previewVoice() async {
        guard let voiceId = elevenLabsSettings.selectedVoiceId else { return }

        isPreviewingVoice = true
        elevenLabsTestResult = nil

        // Preview text in Swedish
        let previewText = "Hej! Det här är en förhandsvisning av rösten. Så här kommer din text att låta."

        do {
            let audioData = try await ElevenLabsService.shared.generateSpeech(text: previewText, voiceId: voiceId)
            previewAudioPlayer = try AVAudioPlayer(data: audioData)
            previewAudioPlayer?.play()
        } catch {
            elevenLabsTestResult = .failure("Preview failed: \(error.localizedDescription)")
        }

        isPreviewingVoice = false
    }

    private func testElevenLabsConnection() async {
        isTestingElevenLabs = true
        elevenLabsTestResult = nil
        do {
            _ = try await ElevenLabsService.shared.testConnection()
            elevenLabsTestResult = .success
        } catch {
            elevenLabsTestResult = .failure(error.localizedDescription)
        }
        isTestingElevenLabs = false
    }

    private func testConnection(for provider: AIModelProvider) async {
        switch provider {
        case .openAI:
            isTestingOpenAI = true
            openAITestResult = nil
            do {
                _ = try await OpenAIService.shared.testConnection()
                openAITestResult = .success
            } catch {
                openAITestResult = .failure(error.localizedDescription)
            }
            isTestingOpenAI = false

        case .claude:
            isTestingClaude = true
            claudeTestResult = nil
            do {
                _ = try await ClaudeAPIService.shared.testConnection()
                claudeTestResult = .success
            } catch {
                claudeTestResult = .failure(error.localizedDescription)
            }
            isTestingClaude = false
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formattedSize(_ size: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(BackupManager())
            .environment(ThemeManager())
    }
}
