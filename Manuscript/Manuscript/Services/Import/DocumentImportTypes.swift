import Foundation

/// Shared result types for single-document imports (DOCX, PDF, HTML, etc.)
struct DocumentImportResult {
    let document: ManuscriptDocument.Document
    let title: String
    let warnings: [ImportWarning]

    var hasWarnings: Bool { !warnings.isEmpty }
}

/// Shared options for document imports
struct DocumentImportOptions {
    /// Whether to preserve formatting where possible
    var preserveFormatting: Bool = true

    /// Whether to import as a new project or add to existing folder
    var createNewProject: Bool = false

    nonisolated static let `default` = DocumentImportOptions()
}

/// Shared validation result for document imports
struct DocumentValidationResult {
    let isValid: Bool
    var documentTitle: String = ""
    var fileSize: Int64 = 0
    var warnings: [String] = []
    var errors: [String] = []

    var fileSizeFormatted: String {
        if fileSize < 1024 {
            return "\(fileSize) B"
        } else if fileSize < 1024 * 1024 {
            return "\(fileSize / 1024) KB"
        } else {
            return String(format: "%.1f MB", Double(fileSize) / (1024 * 1024))
        }
    }
}

// Backwards-compatible aliases for existing importers/views.
typealias DOCXImportResult = DocumentImportResult
typealias DOCXValidationResult = DocumentValidationResult
typealias DOCXImportOptions = DocumentImportOptions
