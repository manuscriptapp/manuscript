import Foundation

// MARK: - Export Format

enum ExportFormat: String, Codable, CaseIterable, Identifiable {
    case pdf = "PDF"
    case docx = "Word"
    case epub = "EPUB"
    case markdown = "Markdown"
    case plainText = "Plain Text"
    case html = "HTML"
    case scrivener = "Scrivener"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .docx: return "docx"
        case .epub: return "epub"
        case .markdown: return "md"
        case .plainText: return "txt"
        case .html: return "html"
        case .scrivener: return "scriv"
        }
    }

    var systemImage: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .docx: return "doc.fill"
        case .epub: return "book.fill"
        case .markdown: return "doc.text"
        case .plainText: return "doc.plaintext"
        case .html: return "chevron.left.slash.chevron.right"
        case .scrivener: return "folder.fill"
        }
    }

    /// Whether this format produces a folder/package instead of a single file
    var isPackageFormat: Bool {
        switch self {
        case .scrivener: return true
        default: return false
        }
    }
}

// MARK: - Page Size

enum PageSize: String, Codable, CaseIterable, Identifiable {
    case letter = "US Letter"
    case a4 = "A4"

    var id: String { rawValue }

    var dimensions: CGSize {
        switch self {
        case .letter: return CGSize(width: 612, height: 792)  // 8.5 x 11 inches at 72 dpi
        case .a4: return CGSize(width: 595, height: 842)      // 210 x 297 mm at 72 dpi
        }
    }
}

// MARK: - Font Style

enum CompileFontStyle: String, Codable, CaseIterable, Identifiable {
    case serif = "Serif"
    case sansSerif = "Sans Serif"
    case monospace = "Monospace"

    var id: String { rawValue }

    var fontName: String {
        switch self {
        case .serif: return "Georgia"
        case .sansSerif: return "Helvetica Neue"
        case .monospace: return "Menlo"
        }
    }
}

// MARK: - Document Separator

enum DocumentSeparator: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case blankLine = "Blank Line"
    case threeAsterisks = "***"
    case pageBreak = "Page Break"
    case chapterHeading = "Chapter Heading"

    var id: String { rawValue }

    var markdownSeparator: String {
        switch self {
        case .none: return ""
        case .blankLine: return "\n\n"
        case .threeAsterisks: return "\n\n***\n\n"
        case .pageBreak: return "\n\n---\n\n"  // Rendered as page break in some renderers
        case .chapterHeading: return ""  // Handled specially
        }
    }
}

// MARK: - Compile Settings

struct CompileSettings: Codable, Equatable {
    // Content options
    var titleOverride: String?
    var authorOverride: String?
    var includeFrontMatter: Bool
    var includeTableOfContents: Bool
    var documentSeparator: DocumentSeparator

    // PDF-specific options
    var pageSize: PageSize
    var fontStyle: CompileFontStyle
    var fontSize: CGFloat
    var lineSpacing: CGFloat
    var margins: CompileEdgeInsets
    var includePageNumbers: Bool
    var includeTitlePage: Bool
    var includeChapterTitles: Bool

    // Export format
    var format: ExportFormat

    init(
        titleOverride: String? = nil,
        authorOverride: String? = nil,
        includeFrontMatter: Bool = true,
        includeTableOfContents: Bool = false,
        documentSeparator: DocumentSeparator = .chapterHeading,
        pageSize: PageSize = .letter,
        fontStyle: CompileFontStyle = .serif,
        fontSize: CGFloat = 12,
        lineSpacing: CGFloat = 1.5,
        margins: CompileEdgeInsets = .oneInch,
        includePageNumbers: Bool = true,
        includeTitlePage: Bool = true,
        includeChapterTitles: Bool = true,
        format: ExportFormat = .pdf
    ) {
        self.titleOverride = titleOverride
        self.authorOverride = authorOverride
        self.includeFrontMatter = includeFrontMatter
        self.includeTableOfContents = includeTableOfContents
        self.documentSeparator = documentSeparator
        self.pageSize = pageSize
        self.fontStyle = fontStyle
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.margins = margins
        self.includePageNumbers = includePageNumbers
        self.includeTitlePage = includeTitlePage
        self.includeChapterTitles = includeChapterTitles
        self.format = format
    }
}

// MARK: - Compile Edge Insets

struct CompileEdgeInsets: Codable, Equatable {
    var top: CGFloat
    var leading: CGFloat
    var bottom: CGFloat
    var trailing: CGFloat

    init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    init(all: CGFloat) {
        self.top = all
        self.leading = all
        self.bottom = all
        self.trailing = all
    }

    /// Default 1-inch margins (72 points)
    static let oneInch = CompileEdgeInsets(all: 72)
}

// MARK: - Compilable Document

/// Represents a document ready for compilation with its metadata
struct CompilableDocument: Identifiable {
    let id: UUID
    let title: String
    let content: String
    let order: Int
    let depth: Int  // 0 for root level, 1 for subfolder, etc.
    let parentTitle: String?

    var wordCount: Int {
        content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}

// MARK: - Compile Result

enum CompileResult {
    case success(data: Data, filename: String)
    case failure(error: CompileError)
}

// MARK: - Compile Error

enum CompileError: LocalizedError {
    case noDocuments
    case exportFailed(underlying: Error)
    case pdfGenerationFailed
    case fileWriteFailed

    var errorDescription: String? {
        switch self {
        case .noDocuments:
            return "No documents to compile. Make sure at least one document is marked for inclusion."
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        case .pdfGenerationFailed:
            return "Failed to generate PDF."
        case .fileWriteFailed:
            return "Failed to write the exported file."
        }
    }
}

// MARK: - Compile Progress

struct CompileProgress {
    var currentDocument: Int
    var totalDocuments: Int
    var currentPhase: CompilePhase

    var fraction: Double {
        guard totalDocuments > 0 else { return 0 }
        return Double(currentDocument) / Double(totalDocuments)
    }

    var description: String {
        switch currentPhase {
        case .collecting:
            return "Collecting documents..."
        case .processing:
            return "Processing document \(currentDocument) of \(totalDocuments)..."
        case .generating:
            return "Generating output..."
        case .complete:
            return "Complete"
        }
    }
}

enum CompilePhase {
    case collecting
    case processing
    case generating
    case complete
}
