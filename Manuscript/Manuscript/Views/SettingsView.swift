import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultAuthorName") private var defaultAuthorName: String = ""
    @State private var aiSettings = AISettingsManager.shared

    // API Key input states
    @State private var openAIKeyInput: String = ""
    @State private var claudeKeyInput: String = ""
    @State private var showOpenAIKey: Bool = false
    @State private var showClaudeKey: Bool = false

    // Connection test states
    @State private var isTestingOpenAI: Bool = false
    @State private var isTestingClaude: Bool = false
    @State private var openAITestResult: TestResult?
    @State private var claudeTestResult: TestResult?

    enum TestResult {
        case success
        case failure(String)
    }

    var body: some View {
        Form {
            Section("Author") {
                TextField("Default Author Name", text: $defaultAuthorName)
                    .textFieldStyle(.automatic)
                #if os(iOS)
                    .textInputAutocapitalization(.words)
                #endif
            }

            aiSettingsSection

            Section("App Info") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadExistingKeys()
        }
    }

    // MARK: - AI Settings Section

    @ViewBuilder
    private var aiSettingsSection: some View {
        Section {
            // Disclaimer
            Text("AI features are coming soon. Configure your API keys now to be ready when they launch.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
                .padding(.vertical, 4)

            // Model Provider Picker
            Picker("AI Provider", selection: $aiSettings.selectedProvider) {
                ForEach(AIModelProvider.allCases) { provider in
                    VStack(alignment: .leading) {
                        Text(provider.displayName)
                    }
                    .tag(provider)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            // Provider description
            Text(aiSettings.selectedProvider.description)
                .font(.caption)
                .foregroundStyle(.secondary)

        } header: {
            Text("AI Settings")
        } footer: {
            Text("API keys are securely stored in your iCloud Keychain and sync across your Apple devices.")
        }

        // OpenAI Settings
        if aiSettings.selectedProvider == .openAI || aiSettings.selectedProvider == .auto {
            Section("OpenAI") {
                openAIKeyField

                if aiSettings.selectedProvider == .openAI {
                    Picker("Model", selection: $aiSettings.selectedOpenAIModel) {
                        ForEach(OpenAIModel.allCases) { model in
                            VStack(alignment: .leading) {
                                Text(model.displayName)
                                Text(model.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(model)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.navigationLink)
                    #endif
                }

                // Test connection button
                if aiSettings.hasOpenAIKey {
                    testConnectionButton(for: .openAI)
                }
            }
        }

        // Claude Settings
        if aiSettings.selectedProvider == .claude || aiSettings.selectedProvider == .auto {
            Section("Claude (Anthropic)") {
                claudeKeyField

                if aiSettings.selectedProvider == .claude {
                    Picker("Model", selection: $aiSettings.selectedClaudeModel) {
                        ForEach(ClaudeModel.allCases) { model in
                            VStack(alignment: .leading) {
                                Text(model.displayName)
                                Text(model.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(model)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.navigationLink)
                    #endif
                }

                // Test connection button
                if aiSettings.hasClaudeKey {
                    testConnectionButton(for: .claude)
                }
            }
        }
    }

    // MARK: - OpenAI Key Field

    @ViewBuilder
    private var openAIKeyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if showOpenAIKey {
                    TextField("OpenAI API Key", text: $openAIKeyInput)
                        .textFieldStyle(.automatic)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                } else {
                    SecureField("OpenAI API Key", text: $openAIKeyInput)
                        .textFieldStyle(.automatic)
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
                    Text("Key saved: \(aiSettings.openAIKeyPreview)")
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
                Button("Save Key") {
                    saveOpenAIKey()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }

        // Show test result
        if let result = openAITestResult {
            testResultView(result)
        }
    }

    // MARK: - Claude Key Field

    @ViewBuilder
    private var claudeKeyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if showClaudeKey {
                    TextField("Claude API Key", text: $claudeKeyInput)
                        .textFieldStyle(.automatic)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                } else {
                    SecureField("Claude API Key", text: $claudeKeyInput)
                        .textFieldStyle(.automatic)
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
                    Text("Key saved: \(aiSettings.claudeKeyPreview)")
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
                Button("Save Key") {
                    saveClaudeKey()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }

        // Show test result
        if let result = claudeTestResult {
            testResultView(result)
        }
    }

    // MARK: - Test Connection Button

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

    // MARK: - Test Result View

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

    // MARK: - Actions

    private func loadExistingKeys() {
        // Clear input fields - we show preview of saved keys separately
        openAIKeyInput = ""
        claudeKeyInput = ""
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

        case .auto:
            break
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
