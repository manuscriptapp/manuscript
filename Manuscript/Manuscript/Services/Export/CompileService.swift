import Foundation

/// Service that orchestrates the compilation/export of manuscript documents
class CompileService {
    static let shared = CompileService()

    private init() {}

    // MARK: - Document Collection

    /// Collects all compilable documents from a folder hierarchy
    /// - Parameters:
    ///   - folder: The root folder to collect from
    ///   - depth: Current depth in the hierarchy
    /// - Returns: Array of compilable documents in order
    func collectCompilableDocuments(
        from folder: ManuscriptFolder,
        depth: Int = 0,
        parentTitle: String? = nil
    ) -> [CompilableDocument] {
        var documents: [CompilableDocument] = []

        // Collect documents from this folder, respecting includeInCompile flag
        let sortedDocuments = folder.documents
            .filter { $0.includeInCompile }
            .sorted { $0.order < $1.order }

        for document in sortedDocuments {
            let compilable = CompilableDocument(
                id: document.id,
                title: document.title,
                content: document.content,
                order: document.order,
                depth: depth,
                parentTitle: parentTitle ?? folder.title
            )
            documents.append(compilable)
        }

        // Recursively collect from subfolders
        let sortedSubfolders = folder.subfolders.sorted { $0.order < $1.order }
        for subfolder in sortedSubfolders {
            let subDocs = collectCompilableDocuments(
                from: subfolder,
                depth: depth + 1,
                parentTitle: subfolder.title
            )
            documents.append(contentsOf: subDocs)
        }

        return documents
    }

    // MARK: - Compilation

    /// Compiles a manuscript document to the specified format
    /// - Parameters:
    ///   - document: The manuscript document to compile
    ///   - settings: The compile settings
    ///   - progress: Optional progress callback
    /// - Returns: The compiled data and suggested filename
    func compile(
        document: ManuscriptDocument,
        settings: CompileSettings,
        progress: ((CompileProgress) -> Void)? = nil
    ) async throws -> (data: Data, filename: String) {
        // Report progress
        progress?(CompileProgress(currentDocument: 0, totalDocuments: 0, currentPhase: .collecting))

        // Collect documents
        let compilableDocuments = collectCompilableDocuments(from: document.rootFolder)

        guard !compilableDocuments.isEmpty else {
            throw CompileError.noDocuments
        }

        // Get metadata
        let title = settings.titleOverride?.isEmpty == false
            ? settings.titleOverride!
            : document.title.isEmpty ? "Untitled" : document.title
        let author = settings.authorOverride?.isEmpty == false
            ? settings.authorOverride!
            : document.author

        // Export based on format
        let data: Data
        let fileExtension: String

        switch settings.format {
        case .pdf:
            data = try await PDFExporter.shared.export(
                documents: compilableDocuments,
                title: title,
                author: author,
                settings: settings,
                progress: progress
            )
            fileExtension = "pdf"

        case .markdown:
            data = try await MarkdownExporter.shared.export(
                documents: compilableDocuments,
                title: title,
                author: author,
                settings: settings,
                progress: progress
            )
            fileExtension = "md"

        case .plainText:
            data = try await PlainTextExporter.shared.export(
                documents: compilableDocuments,
                title: title,
                author: author,
                settings: settings,
                progress: progress
            )
            fileExtension = "txt"
        }

        // Report complete
        progress?(CompileProgress(
            currentDocument: compilableDocuments.count,
            totalDocuments: compilableDocuments.count,
            currentPhase: .complete
        ))

        // Generate filename
        let safeTitle = title.slugified
        let filename = "\(safeTitle).\(fileExtension)"

        return (data, filename)
    }

    // MARK: - Statistics

    /// Calculates statistics for a collection of documents
    func calculateStatistics(documents: [CompilableDocument]) -> CompileStatistics {
        let totalWords = documents.reduce(0) { $0 + $1.wordCount }
        let totalCharacters = documents.reduce(0) { $0 + $1.content.count }

        return CompileStatistics(
            documentCount: documents.count,
            wordCount: totalWords,
            characterCount: totalCharacters
        )
    }
}

// MARK: - Compile Statistics

struct CompileStatistics {
    let documentCount: Int
    let wordCount: Int
    let characterCount: Int

    var formattedWordCount: String {
        wordCount.formatted()
    }

    var estimatedPages: Int {
        // Rough estimate: ~250 words per page
        max(1, wordCount / 250)
    }
}
