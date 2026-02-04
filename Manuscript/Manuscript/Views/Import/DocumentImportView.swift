//
//  DocumentImportView.swift
//  Manuscript
//
//  View for importing external documents (DOCX, PDF, HTML) into a Manuscript project.
//

import SwiftUI
import UniformTypeIdentifiers

#if canImport(AppKit)
import AppKit
#endif

/// Supported import file types
enum ImportFileType: String, CaseIterable, Identifiable {
    case docx = "Word Document (.docx)"
    case doc = "Word Document (.doc)"
    case pdf = "PDF Document (.pdf)"
    case html = "HTML Document (.html)"

    var id: String { rawValue }

    var utTypes: [UTType] {
        switch self {
        case .docx:
            return [UTType(filenameExtension: "docx")].compactMap { $0 }
        case .doc:
            return [UTType(filenameExtension: "doc")].compactMap { $0 }
        case .pdf:
            return [.pdf]
        case .html:
            return [UTType.html, UTType(filenameExtension: "html"), UTType(filenameExtension: "htm")].compactMap { $0 }
        }
    }

    static var allUTTypes: [UTType] {
        allCases.flatMap { $0.utTypes }
    }

    static var availableCases: [ImportFileType] {
        #if os(iOS)
        return [.pdf, .html]
        #else
        return allCases
        #endif
    }

    static var availableUTTypes: [UTType] {
        availableCases.flatMap { $0.utTypes }
    }

    var icon: String {
        switch self {
        case .docx, .doc:
            return "doc.fill"
        case .pdf:
            return "doc.richtext"
        case .html:
            return "chevron.left.slash.chevron.right"
        }
    }

    static func from(url: URL) -> ImportFileType? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "docx":
            return .docx
        case "doc":
            return .doc
        case "pdf":
            return .pdf
        case "html", "htm":
            return .html
        default:
            return nil
        }
    }
}

/// View for importing documents into a Manuscript project
struct DocumentImportView: View {
    @Environment(\.dismiss) private var dismiss

    // The folder to import into
    let targetFolder: ManuscriptFolder

    // Callback when import is complete
    var onImportComplete: ((ManuscriptDocument.Document) -> Void)?

    @State private var importState: ImportState = .idle
    @State private var selectedURLs: [URL] = []
    @State private var validationResult: DocumentValidationResult?
    @State private var importResult: DocumentImportResult?
    @State private var progress: Double = 0
    @State private var statusMessage = ""
    @State private var error: Error?
    @State private var isFileImporterPresented = false

    // Import options
    @State private var preserveFormatting = true

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
            .navigationTitle("Import Document")
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
            #if os(iOS)
            .background(fileImporterView)
            #endif
        }
    }

    // MARK: - View States

    private var selectFileView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.badge.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Import Document")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Select a document to import into your project. The document will be added to \"\(targetFolder.title)\".")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Text("Supported formats:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    ForEach(ImportFileType.availableCases, id: \.self) { type in
                        Label(type.rawValue.components(separatedBy: " ").first ?? "", systemImage: type.icon)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }

            Button {
                #if os(iOS)
                isFileImporterPresented = true
                #else
                selectFile()
                #endif
            } label: {
                Label("Select Document...", systemImage: "folder")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var validatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Validating document...")
                .font(.headline)
        }
    }

    private func validationResultView(_ result: DocumentValidationResult) -> some View {
        VStack(spacing: 20) {
            // Document info
            VStack(spacing: 8) {
                Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(result.isValid ? .green : .red)

                Text(result.documentTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(result.fileSizeFormatted)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Warnings
            if !result.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Notes", systemImage: "info.circle")
                        .font(.headline)
                        .foregroundColor(.blue)

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
                .background(Color.blue.opacity(0.1))
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

                    Toggle("Preserve formatting (bold, italic, etc.)", isOn: $preserveFormatting)
                        .disabled(selectedFileType == .pdf)

                    if selectedFileType == .pdf {
                        Text("PDFs are imported as plain text.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Will be imported to: \(targetFolder.title)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                    selectedURLs = []
                    validationResult = nil
                }

                Spacer()

                if result.isValid {
                    Button(action: startImport) {
                        Label("Import Document", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var importingView: some View {
        VStack(spacing: 20) {
            Text("Importing Document")
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

    private func completeView(_ result: DocumentImportResult) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Import Complete!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\"\(result.title)\" has been imported successfully.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Show warnings if any
            if result.hasWarnings {
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(result.warnings.count) note\(result.warnings.count == 1 ? "" : "s")", systemImage: "info.circle")
                        .font(.headline)
                        .foregroundColor(.blue)

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
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            Button("Done") {
                onImportComplete?(result.document)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
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
                    selectedURLs = []
                    error = nil
                }

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Actions

    private func selectFile() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = ImportFileType.availableUTTypes

        panel.message = "Select a document to import"
        panel.prompt = "Import"

        if panel.runModal() == .OK, let url = panel.url {
            selectedURLs = [url]
            validateSelectedFile()
        }
        #else
        // iOS uses the .fileImporter modifier via fileImporterView
        #endif
    }

    private func validateSelectedFile() {
        guard let url = selectedURLs.first else { return }
        guard let fileType = ImportFileType.from(url: url) else {
            error = ImportError.rtfConversionFailed("Unsupported file type.")
            importState = .error
            return
        }
        if fileType == .pdf {
            preserveFormatting = false
        }

        importState = .validating

        Task {
            let result: DocumentValidationResult
            switch fileType {
            case .docx, .doc:
                result = DOCXImporter().validate(at: url)
            case .pdf:
                result = PDFImporter().validate(at: url)
            case .html:
                result = HTMLImporter().validate(at: url)
            }

            await MainActor.run {
                validationResult = result
                importState = .validated
            }
        }
    }

    private func startImport() {
        guard let url = selectedURLs.first else { return }
        guard let fileType = ImportFileType.from(url: url) else {
            error = ImportError.rtfConversionFailed("Unsupported file type.")
            importState = .error
            return
        }

        importState = .importing
        progress = 0

        Task {
            let options = DocumentImportOptions(
                preserveFormatting: preserveFormatting
            )

            do {
                let result: DocumentImportResult
                switch fileType {
                case .docx, .doc:
                    result = try await DOCXImporter().importDocument(
                        from: url,
                        options: options
                    ) { prog, status in
                        Task { @MainActor in
                            self.progress = prog
                            self.statusMessage = status
                        }
                    }
                case .pdf:
                    result = try await PDFImporter().importDocument(
                        from: url,
                        options: options
                    ) { prog, status in
                        Task { @MainActor in
                            self.progress = prog
                            self.statusMessage = status
                        }
                    }
                case .html:
                    result = try await HTMLImporter().importDocument(
                        from: url,
                        options: options
                    ) { prog, status in
                        Task { @MainActor in
                            self.progress = prog
                            self.statusMessage = status
                        }
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

    private var selectedFileType: ImportFileType? {
        guard let url = selectedURLs.first else { return nil }
        return ImportFileType.from(url: url)
    }

    #if os(iOS)
    private var fileImporterView: some View {
        EmptyView()
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: ImportFileType.availableUTTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    selectedURLs = urls
                    validateSelectedFile()
                case .failure(let error):
                    self.error = error
                    importState = .error
                }
            }
    }
    #endif

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
    DocumentImportView(
        targetFolder: ManuscriptFolder(title: "Draft", folderType: .draft)
    )
}
