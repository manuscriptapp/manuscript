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
    @State private var geminiKeyInput: String = ""
    @State private var grokKeyInput: String = ""
    @State private var deepSeekKeyInput: String = ""
    @State private var elevenLabsKeyInput: String = ""
    @State private var showOpenAIKey: Bool = false
    @State private var showClaudeKey: Bool = false
    @State private var showGeminiKey: Bool = false
    @State private var showGrokKey: Bool = false
    @State private var showDeepSeekKey: Bool = false
    @State private var showElevenLabsKey: Bool = false

    // Ollama configuration
    @State private var ollamaEndpointInput: String = ""
    @State private var ollamaCustomModelInput: String = ""
    @State private var ollamaLocalModels: [String] = []
    @State private var isLoadingOllamaModels: Bool = false

    // Connection test states
    @State private var isTestingOpenAI: Bool = false
    @State private var isTestingClaude: Bool = false
    @State private var isTestingGemini: Bool = false
    @State private var isTestingGrok: Bool = false
    @State private var isTestingDeepSeek: Bool = false
    @State private var isTestingOllama: Bool = false
    @State private var isTestingElevenLabs: Bool = false
    @State private var openAITestResult: TestResult?
    @State private var claudeTestResult: TestResult?
    @State private var geminiTestResult: TestResult?
    @State private var grokTestResult: TestResult?
    @State private var deepSeekTestResult: TestResult?
    @State private var ollamaTestResult: TestResult?
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

    @ViewBuilder
    private func settingsNavigationLabel(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
            Text(title)
        }
    }

    @ViewBuilder
    private func settingsActionLabel(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
            Text(title)
        }
    }

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
                    settingsNavigationLabel(SettingsTab.general.rawValue, systemImage: SettingsTab.general.icon)
                }
                .tag(SettingsTab.general)

            formatTabContent
                .tabItem {
                    settingsNavigationLabel(SettingsTab.format.rawValue, systemImage: SettingsTab.format.icon)
                }
                .tag(SettingsTab.format)

            aiTabContent
                .tabItem {
                    settingsNavigationLabel(SettingsTab.ai.rawValue, systemImage: SettingsTab.ai.icon)
                }
                .tag(SettingsTab.ai)

            speechTabContent
                .tabItem {
                    settingsNavigationLabel(SettingsTab.speech.rawValue, systemImage: SettingsTab.speech.icon)
                }
                .tag(SettingsTab.speech)

            backupTabContent
                .tabItem {
                    settingsNavigationLabel(SettingsTab.backups.rawValue, systemImage: SettingsTab.backups.icon)
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
                        settingsNavigationLabel(tab.rawValue, systemImage: tab.icon)
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
                Link("Privacy Policy", destination: URL(string: "https://manuscriptapp.github.io/manuscript/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://manuscriptapp.github.io/manuscript/terms")!)
                Link("Support", destination: URL(string: "https://manuscriptapp.github.io/manuscript/support")!)
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
                    Link("Privacy Policy", destination: URL(string: "https://manuscriptapp.github.io/manuscript/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://manuscriptapp.github.io/manuscript/terms")!)
                    Link("Support", destination: URL(string: "https://manuscriptapp.github.io/manuscript/support")!)
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
                    settingsActionLabel("Backing up…", systemImage: "arrow.triangle.2.circlepath")
                } else {
                    settingsActionLabel("Back Up Now", systemImage: "externaldrive.badge.plus")
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
            Picker("Provider", selection: $aiSettings.selectedProviderKind) {
                ForEach(ModelProviderKind.allCases) { provider in
                    Label(provider.displayName, systemImage: provider.iconName)
                        .tag(provider)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            Text(aiSettings.selectedProviderKind.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        // Model selection (shown for all providers)
        Section("Model") {
            anyModelPicker

            if aiSettings.selectedProviderKind == .local {
                ollamaConfigSection
            }
        }

        // API Key section (shown for cloud providers)
        if aiSettings.selectedProviderKind.requiresAPIKey {
            Section("\(aiSettings.selectedProviderKind.displayName) API Key") {
                providerKeyField(for: aiSettings.selectedProviderKind)
            }
        }
    }

    @ViewBuilder
    private var anyModelPicker: some View {
        let modelBinding = Binding<String>(
            get: { aiSettings.selectedModelId ?? "" },
            set: { aiSettings.selectedModelId = $0 }
        )

        Picker("Model", selection: modelBinding) {
            ForEach(aiSettings.availableModels) { model in
                VStack(alignment: .leading) {
                    Text(model.displayName)
                }
                .tag(model.id)
            }
        }
        #if os(iOS)
        .pickerStyle(.navigationLink)
        #endif

        Text(aiSettings.selectedModel.subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var ollamaConfigSection: some View {
        TextField("Ollama Endpoint", text: $ollamaEndpointInput, prompt: Text("http://localhost:11434"))
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.URL)
            #endif
            .onSubmit {
                if !ollamaEndpointInput.isEmpty {
                    aiSettings.ollamaEndpoint = ollamaEndpointInput
                }
            }

        TextField("Custom Model Name", text: $ollamaCustomModelInput, prompt: Text("Leave empty to use selection above"))
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            #endif
            .onSubmit {
                aiSettings.ollamaCustomModel = ollamaCustomModelInput
            }

        if !ollamaLocalModels.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Installed Models")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(ollamaLocalModels, id: \.self) { model in
                    Button {
                        aiSettings.ollamaCustomModel = model
                        ollamaCustomModelInput = model
                    } label: {
                        HStack {
                            Text(model)
                                .font(.caption)
                            Spacer()
                            if model == aiSettings.ollamaCustomModel || model == aiSettings.selectedModel.id {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        HStack {
            Button {
                Task { await refreshOllamaModels() }
            } label: {
                HStack {
                    if isLoadingOllamaModels {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.accentColor)
                    }
                    Text("Detect Models")
                }
            }
            .disabled(isLoadingOllamaModels)

            Spacer()

            testProviderConnectionButton(for: .local)
        }

        if let result = ollamaTestResult {
            testResultView(result)
        }
    }

    @ViewBuilder
    private func providerKeyField(for provider: ModelProviderKind) -> some View {
        let keyInput = keyInputBinding(for: provider)
        let showKey = showKeyBinding(for: provider)
        let hasKey = aiSettings.hasAPIKey(for: provider)
        let preview = aiSettings.keyPreview(for: provider)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if showKey.wrappedValue {
                    TextField("API Key", text: keyInput)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                } else {
                    SecureField("API Key", text: keyInput)
                }

                Button {
                    showKey.wrappedValue.toggle()
                } label: {
                    Image(systemName: showKey.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if hasKey && keyInput.wrappedValue.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(preview)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Remove", role: .destructive) {
                        removeAPIKey(for: provider)
                    }
                    .font(.caption)
                }
            }

            if !keyInput.wrappedValue.isEmpty {
                Button("Save") {
                    saveAPIKey(for: provider)
                }
                .manuscriptPrimaryButton()
                .controlSize(.small)
            }
        }

        if hasKey {
            testProviderConnectionButton(for: provider)
        }

        if let result = testResult(for: provider) {
            testResultView(result)
        }
    }

    @ViewBuilder
    private func testProviderConnectionButton(for provider: ModelProviderKind) -> some View {
        let isTesting = isTestingProvider(provider)

        Button {
            Task { await testProviderConnection(provider) }
        } label: {
            HStack {
                if isTesting {
                    ProgressView().controlSize(.small)
                    Text("Testing...")
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Color.accentColor)
                    Text("Test Connection")
                }
            }
        }
        .disabled(isTesting)
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
                                .foregroundStyle(Color.accentColor)
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
                                    .foregroundStyle(Color.accentColor)
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
                        .foregroundStyle(Color.accentColor)
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

    // MARK: - Binding Helpers for Provider Key Fields

    private func keyInputBinding(for provider: ModelProviderKind) -> Binding<String> {
        switch provider {
        case .local:     return .constant("")
        case .openAI:    return $openAIKeyInput
        case .anthropic: return $claudeKeyInput
        case .gemini:    return $geminiKeyInput
        case .grok:      return $grokKeyInput
        case .deepSeek:  return $deepSeekKeyInput
        }
    }

    private func showKeyBinding(for provider: ModelProviderKind) -> Binding<Bool> {
        switch provider {
        case .local:     return .constant(false)
        case .openAI:    return $showOpenAIKey
        case .anthropic: return $showClaudeKey
        case .gemini:    return $showGeminiKey
        case .grok:      return $showGrokKey
        case .deepSeek:  return $showDeepSeekKey
        }
    }

    private func isTestingProvider(_ provider: ModelProviderKind) -> Bool {
        switch provider {
        case .local:     return isTestingOllama
        case .openAI:    return isTestingOpenAI
        case .anthropic: return isTestingClaude
        case .gemini:    return isTestingGemini
        case .grok:      return isTestingGrok
        case .deepSeek:  return isTestingDeepSeek
        }
    }

    private func testResult(for provider: ModelProviderKind) -> TestResult? {
        switch provider {
        case .local:     return ollamaTestResult
        case .openAI:    return openAITestResult
        case .anthropic: return claudeTestResult
        case .gemini:    return geminiTestResult
        case .grok:      return grokTestResult
        case .deepSeek:  return deepSeekTestResult
        }
    }

    // MARK: - Key & Connection Management

    private func loadExistingKeys() {
        openAIKeyInput = ""
        claudeKeyInput = ""
        geminiKeyInput = ""
        grokKeyInput = ""
        deepSeekKeyInput = ""
        elevenLabsKeyInput = ""
        ollamaEndpointInput = aiSettings.ollamaEndpoint
        ollamaCustomModelInput = aiSettings.ollamaCustomModel
    }

    private func saveAPIKey(for provider: ModelProviderKind) {
        let keyInput = keyInputBinding(for: provider)
        do {
            try aiSettings.saveAPIKey(keyInput.wrappedValue, for: provider)
            keyInput.wrappedValue = ""
            setTestResult(nil, for: provider)
        } catch {
            setTestResult(.failure("Failed to save key: \(error.localizedDescription)"), for: provider)
        }
    }

    private func removeAPIKey(for provider: ModelProviderKind) {
        let keyInput = keyInputBinding(for: provider)
        do {
            try aiSettings.deleteAPIKey(for: provider)
            keyInput.wrappedValue = ""
            setTestResult(nil, for: provider)
        } catch {
            setTestResult(.failure("Failed to remove key: \(error.localizedDescription)"), for: provider)
        }
    }

    private func setTestResult(_ result: TestResult?, for provider: ModelProviderKind) {
        switch provider {
        case .local:     ollamaTestResult = result
        case .openAI:    openAITestResult = result
        case .anthropic: claudeTestResult = result
        case .gemini:    geminiTestResult = result
        case .grok:      grokTestResult = result
        case .deepSeek:  deepSeekTestResult = result
        }
    }

    private func setTesting(_ testing: Bool, for provider: ModelProviderKind) {
        switch provider {
        case .local:     isTestingOllama = testing
        case .openAI:    isTestingOpenAI = testing
        case .anthropic: isTestingClaude = testing
        case .gemini:    isTestingGemini = testing
        case .grok:      isTestingGrok = testing
        case .deepSeek:  isTestingDeepSeek = testing
        }
    }

    private func testProviderConnection(_ provider: ModelProviderKind) async {
        setTesting(true, for: provider)
        setTestResult(nil, for: provider)
        do {
            _ = try await TextGenerationService.shared.testConnection(for: provider)
            setTestResult(.success, for: provider)
        } catch {
            setTestResult(.failure(error.localizedDescription), for: provider)
        }
        setTesting(false, for: provider)
    }

    private func refreshOllamaModels() async {
        isLoadingOllamaModels = true
        ollamaTestResult = nil
        do {
            ollamaLocalModels = try await OllamaService.shared.fetchLocalModels()
            if ollamaLocalModels.isEmpty {
                ollamaTestResult = .failure("No models found. Pull a model with: ollama pull llama3.2")
            } else {
                ollamaTestResult = .success
            }
        } catch {
            ollamaTestResult = .failure(error.localizedDescription)
        }
        isLoadingOllamaModels = false
    }

    // MARK: - ElevenLabs Helpers

    private func saveElevenLabsKey() {
        do {
            try elevenLabsSettings.saveAPIKey(elevenLabsKeyInput)
            elevenLabsKeyInput = ""
            elevenLabsTestResult = nil
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
