import SwiftUI
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

/// View for importing Scrivener projects
struct ScrivenerImportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var importState: ImportState = .idle
    @State private var selectedURL: URL?
    @State private var validationResult: ScrivenerValidationResult?
    @State private var importResult: ImportResult?
    @State private var progress: Double = 0
    @State private var statusMessage = ""
    @State private var error: Error?

    // Import options
    @State private var importResearch = true
    @State private var importTrash = false
    @State private var importSnapshots = true

    // Callback when import is complete
    var onImportComplete: ((ManuscriptDocument) -> Void)?

    enum ImportState {
        case idle
        case validating
        case validated
        case importing
        case complete
        case error
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                switch importState {
                case .idle:
                    selectFileView

                case .validating:
                    validatingView

                case .validated:
                    if let result = validationResult {
                        validationResultView(result)
                    }

                case .importing:
                    importingView

                case .complete:
                    if let result = importResult {
                        completeView(result)
                    }

                case .error:
                    errorView
                }
            }
            .padding()
            .frame(minWidth: 400, minHeight: 300)
            .navigationTitle("Import from Scrivener")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            #endif
        }
    }

    // MARK: - View States

    private var selectFileView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.badge.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Import Scrivener Project")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Select a .scriv project to import into Manuscript. Your original Scrivener project will not be modified.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: selectFile) {
                Label("Select Scrivener Project...", systemImage: "folder")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .manuscriptPrimaryButton()
        }
    }

    private var validatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Validating project...")
                .font(.headline)
        }
    }

    private func validationResultView(_ result: ScrivenerValidationResult) -> some View {
        VStack(spacing: 20) {
            // Project info
            VStack(spacing: 8) {
                Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(result.isValid ? .green : .red)

                Text(result.projectTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(result.itemCount) items • Scrivener \(result.version == .v3 ? "3" : "2") format")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Warnings
            if !result.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Warnings", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundColor(.orange)

                    ForEach(result.warnings, id: \.self) { warning in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(warning)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Errors
            if !result.errors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Errors", systemImage: "xmark.circle")
                        .font(.headline)
                        .foregroundColor(.red)

                    ForEach(result.errors, id: \.self) { error in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Import options
            if result.isValid {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import Options")
                        .font(.headline)

                    Toggle("Import Research folder", isOn: $importResearch)
                    Toggle("Import Trash folder", isOn: $importTrash)
                    Toggle("Import Snapshots", isOn: $importSnapshots)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            // Action buttons
            HStack {
                Button("Select Different File") {
                    importState = .idle
                    selectedURL = nil
                    validationResult = nil
                }

                Spacer()

                if result.isValid {
                    Button(action: startImport) {
                        Label("Import Project", systemImage: "square.and.arrow.down")
                    }
                    .manuscriptPrimaryButton()
                }
            }
        }
    }

    private var importingView: some View {
        VStack(spacing: 20) {
            Text("Importing Project")
                .font(.headline)

            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .frame(maxWidth: 300)

            Text(statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }

    private func completeView(_ result: ImportResult) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Import Complete!")
                .font(.title2)
                .fontWeight(.semibold)

            Text(result.summary)
                .font(.body)
                .foregroundColor(.secondary)

            // Show warnings if any
            if result.hasWarnings {
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(result.warnings.count) warning\(result.warnings.count == 1 ? "" : "s")", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundColor(.orange)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(result.warnings) { warning in
                                HStack(alignment: .top) {
                                    Image(systemName: warningIcon(for: warning.severity))
                                        .foregroundColor(warningColor(for: warning.severity))
                                        .font(.caption)
                                    VStack(alignment: .leading) {
                                        if let title = warning.itemTitle {
                                            Text(title)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        Text(warning.message)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            HStack {
                Spacer()
                ManuscriptDoneButton {
                    onImportComplete?(result.document)
                    dismiss()
                }
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Import Failed")
                .font(.title2)
                .fontWeight(.semibold)

            if let error = error {
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Spacer()

            HStack {
                Button("Try Again") {
                    importState = .idle
                    selectedURL = nil
                    error = nil
                }

                Button("Close") {
                    dismiss()
                }
                .manuscriptPrimaryButton()
            }
        }
    }

    // MARK: - Actions

    private func selectFile() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true  // Allow files to show .scrivx inside bundles
        panel.treatsFilePackagesAsDirectories = true  // Allow navigating into .scriv bundles

        panel.message = "Select a Scrivener project (.scriv folder) or navigate inside and select the .scrivx file"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            // Check if it's a .scriv bundle
            if url.pathExtension.lowercased() == "scriv" {
                selectedURL = url
                validateSelectedFile()
            } else if url.pathExtension.lowercased() == "scrivx" {
                // User selected the .scrivx file inside - use the parent directory
                selectedURL = url.deletingLastPathComponent()
                validateSelectedFile()
            } else {
                // Show error - not a .scriv file
                error = NSError(
                    domain: "ScrivenerImport",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Please select a Scrivener project (.scriv) or the .scrivx file inside it"]
                )
                importState = .error
            }
        }
        #else
        // On iOS, we'll need to use a document picker
        // This would typically be handled by a .fileImporter modifier in the parent view
        #endif
    }

    private func validateSelectedFile() {
        guard let url = selectedURL else { return }

        importState = .validating

        Task {
            let importer = ScrivenerImporter()
            let result = importer.validateProject(at: url)

            await MainActor.run {
                validationResult = result
                importState = .validated
            }
        }
    }

    private func startImport() {
        guard let url = selectedURL else { return }

        importState = .importing
        progress = 0

        Task {
            let importer = ScrivenerImporter()
            let options = ScrivenerImportOptions(
                importSnapshots: importSnapshots,
                importTrash: importTrash,
                importResearch: importResearch
            )

            do {
                let result = try await importer.importProject(
                    from: url,
                    options: options
                ) { prog, status in
                    Task { @MainActor in
                        self.progress = prog
                        self.statusMessage = status
                    }
                }

                await MainActor.run {
                    importResult = result
                    importState = .complete
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    importState = .error
                }
            }
        }
    }

    // MARK: - Helpers

    private func warningIcon(for severity: ImportWarning.Severity) -> String {
        switch severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }

    private func warningColor(for severity: ImportWarning.Severity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

#Preview {
    ScrivenerImportView()
}
