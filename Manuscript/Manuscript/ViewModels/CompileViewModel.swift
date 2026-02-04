import SwiftUI
import Combine

/// ViewModel for managing compile/export state
@MainActor
class CompileViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var settings: CompileSettings
    @Published var isCompiling = false
    @Published var progress: CompileProgress?
    @Published var error: CompileError?
    @Published var compiledData: Data?
    @Published var compiledFilename: String?

    // Preview state
    @Published var compilableDocuments: [CompilableDocument] = []
    @Published var statistics: CompileStatistics?

    // MARK: - Private Properties

    private let document: ManuscriptDocument
    private let compileService = CompileService.shared

    // MARK: - Initialization

    init(document: ManuscriptDocument) {
        self.document = document

        // Initialize settings from document's compile settings or defaults
        let existingSettings = document.compileSettings
        self.settings = CompileSettings(
            titleOverride: existingSettings.title.isEmpty ? nil : existingSettings.title,
            authorOverride: existingSettings.author.isEmpty ? nil : existingSettings.author
        )

        // Collect documents for preview
        refreshDocumentList()
    }

    // MARK: - Public Methods

    /// Refreshes the list of compilable documents
    func refreshDocumentList() {
        compilableDocuments = compileService.collectCompilableDocuments(from: document.rootFolder)
        statistics = compileService.calculateStatistics(documents: compilableDocuments)
    }

    /// Gets the effective title (override or document title)
    var effectiveTitle: String {
        if let override = settings.titleOverride, !override.isEmpty {
            return override
        }
        return document.title.isEmpty ? "Untitled" : document.title
    }

    /// Gets the effective author (override or document author)
    var effectiveAuthor: String {
        if let override = settings.authorOverride, !override.isEmpty {
            return override
        }
        return document.author
    }

    /// Compiles the document with current settings
    func compile() async {
        guard !isCompiling else { return }

        isCompiling = true
        error = nil
        compiledData = nil
        compiledFilename = nil

        do {
            let result = try await compileService.compile(
                document: document,
                settings: settings
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.progress = progress
                }
            }

            compiledData = result.data
            compiledFilename = result.filename
        } catch let compileError as CompileError {
            error = compileError
        } catch {
            self.error = .exportFailed(underlying: error)
        }

        isCompiling = false
        progress = nil
    }

    /// Resets the compiled result
    func resetResult() {
        compiledData = nil
        compiledFilename = nil
        error = nil
    }

    // MARK: - Format Change Handler

    func updateFormat(_ format: ExportFormat) {
        settings.format = format

        // Adjust defaults based on format
        switch format {
        case .pdf:
            settings.includeTitlePage = true
        case .docx:
            settings.includeTitlePage = true
        case .epub:
            settings.includeTitlePage = true
        case .markdown:
            settings.includeFrontMatter = true
            settings.includeTitlePage = false
        case .plainText:
            settings.includeFrontMatter = false
            settings.includeTitlePage = false
        case .html:
            settings.includeFrontMatter = false
            settings.includeTitlePage = false
        case .scrivener:
            settings.includeTitlePage = false
        }
    }
}
