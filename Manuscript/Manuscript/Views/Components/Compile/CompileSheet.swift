import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct CompileSheet: View {
    @StateObject private var viewModel: CompileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false

    init(document: ManuscriptDocument) {
        self._viewModel = StateObject(wrappedValue: CompileViewModel(document: document))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Format section
                formatSection

                // Content options section
                contentOptionsSection

                // Format-specific options
                if viewModel.settings.format == .pdf {
                    pdfOptionsSection
                }

                // Preview section
                previewSection
            }
            .formStyle(.grouped)
            .navigationTitle("Export")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.compile()
                            if viewModel.compiledData != nil {
                                #if os(iOS)
                                showShareSheet = true
                                #else
                                saveOnMacOS()
                                #endif
                            }
                        }
                    } label: {
                        if viewModel.isCompiling {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Export")
                        }
                    }
                    .disabled(viewModel.isCompiling || viewModel.compilableDocuments.isEmpty)
                }
            }
            .overlay {
                if viewModel.isCompiling {
                    compileProgressOverlay
                }
            }
            .alert("Export Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showShareSheet) {
                if let data = viewModel.compiledData,
                   let filename = viewModel.compiledFilename {
                    ShareSheet(data: data, filename: filename)
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 500)
        #endif
    }

    // MARK: - Format Section

    private var formatSection: some View {
        Section("Format") {
            Picker("Export Format", selection: Binding(
                get: { viewModel.settings.format },
                set: { viewModel.updateFormat($0) }
            )) {
                ForEach(ExportFormat.allCases) { format in
                    Label(format.rawValue, systemImage: format.systemImage)
                        .tag(format)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Content Options Section

    private var contentOptionsSection: some View {
        Section("Content") {
            TextField("Title", text: Binding(
                get: { viewModel.settings.titleOverride ?? "" },
                set: { viewModel.settings.titleOverride = $0.isEmpty ? nil : $0 }
            ), prompt: Text(viewModel.effectiveTitle))

            TextField("Author", text: Binding(
                get: { viewModel.settings.authorOverride ?? "" },
                set: { viewModel.settings.authorOverride = $0.isEmpty ? nil : $0 }
            ), prompt: Text(viewModel.effectiveAuthor.isEmpty ? "Author" : viewModel.effectiveAuthor))

            Toggle("Include Table of Contents", isOn: $viewModel.settings.includeTableOfContents)

            Toggle("Include Chapter Titles", isOn: $viewModel.settings.includeChapterTitles)

            Picker("Document Separator", selection: $viewModel.settings.documentSeparator) {
                ForEach(DocumentSeparator.allCases) { separator in
                    Text(separator.rawValue).tag(separator)
                }
            }

            if viewModel.settings.format == .markdown {
                Toggle("Include YAML Frontmatter", isOn: $viewModel.settings.includeFrontMatter)
            }
        }
    }

    // MARK: - PDF Options Section

    private var pdfOptionsSection: some View {
        Section("PDF Options") {
            Toggle("Include Title Page", isOn: $viewModel.settings.includeTitlePage)

            Toggle("Include Page Numbers", isOn: $viewModel.settings.includePageNumbers)

            Picker("Page Size", selection: $viewModel.settings.pageSize) {
                ForEach(PageSize.allCases) { size in
                    Text(size.rawValue).tag(size)
                }
            }

            Picker("Font Style", selection: $viewModel.settings.fontStyle) {
                ForEach(CompileFontStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }

            HStack {
                Text("Font Size")
                Spacer()
                Stepper(
                    "\(Int(viewModel.settings.fontSize)) pt",
                    value: $viewModel.settings.fontSize,
                    in: 8...24,
                    step: 1
                )
            }

            HStack {
                Text("Line Spacing")
                Spacer()
                Stepper(
                    String(format: "%.1f", viewModel.settings.lineSpacing),
                    value: $viewModel.settings.lineSpacing,
                    in: 1.0...3.0,
                    step: 0.25
                )
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        Section {
            if viewModel.compilableDocuments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Documents to Export")
                        .font(.headline)
                    Text("Make sure at least one document is marked for inclusion in compile.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            } else {
                // Statistics
                if let stats = viewModel.statistics {
                    LabeledContent("Documents", value: "\(stats.documentCount)")
                    LabeledContent("Words", value: stats.formattedWordCount)
                    LabeledContent("Est. Pages", value: "\(stats.estimatedPages)")
                }

                // Document list
                DisclosureGroup("Included Documents (\(viewModel.compilableDocuments.count))") {
                    ForEach(viewModel.compilableDocuments) { doc in
                        HStack {
                            let indent = CGFloat(doc.depth) * 16
                            Spacer().frame(width: indent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title.isEmpty ? "Untitled" : doc.title)
                                    .font(.subheadline)
                                Text("\(doc.wordCount) words")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Preview")
                Spacer()
                Button {
                    viewModel.refreshDocumentList()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    // MARK: - Progress Overlay

    private var compileProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)

                if let progress = viewModel.progress {
                    Text(progress.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ProgressView(value: progress.fraction)
                        .frame(width: 200)
                }
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - macOS Save

    #if os(macOS)
    private func saveOnMacOS() {
        guard let data = viewModel.compiledData,
              let filename = viewModel.compiledFilename else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [contentType(for: viewModel.settings.format)]
        savePanel.nameFieldStringValue = filename
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url)
                    dismiss()
                } catch {
                    viewModel.error = .fileWriteFailed
                }
            }
        }
    }

    private func contentType(for format: ExportFormat) -> UTType {
        switch format {
        case .pdf: return .pdf
        case .docx: return UTType(filenameExtension: "docx") ?? .data
        case .epub: return UTType(filenameExtension: "epub") ?? .data
        case .markdown: return UTType(filenameExtension: "md") ?? .plainText
        case .plainText: return .plainText
        }
    }
    #endif
}

// MARK: - iOS Share Sheet

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
        } catch {
            print("Failed to write temp file: \(error)")
        }

        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Preview

#if DEBUG
struct CompileSheetPreview: PreviewProvider {
    static var previews: some View {
        CompileSheet(document: {
            var doc = ManuscriptDocument()
            doc.title = "My Novel"
            doc.author = "Jane Doe"

            // Add sample documents
            doc.rootFolder.documents = [
                ManuscriptDocument.Document(
                    title: "Chapter 1",
                    content: "It was a dark and stormy night..."
                ),
                ManuscriptDocument.Document(
                    title: "Chapter 2",
                    content: "The morning came slowly..."
                )
            ]

            return doc
        }())
    }
}
#endif
