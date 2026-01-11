import Foundation

/// Errors that can occur during Scrivener project import
enum ImportError: LocalizedError {
    case notABundle
    case missingProjectFile
    case xmlParsingFailed(String)
    case rtfConversionFailed(String)
    case missingContent(itemID: String)
    case unsupportedVersion(String)
    case fileReadFailed(String)
    case invalidBundleStructure(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notABundle:
            return "The selected file is not a valid Scrivener project bundle."
        case .missingProjectFile:
            return "Could not find project.scrivx in the Scrivener bundle."
        case .xmlParsingFailed(let detail):
            return "Failed to parse project file: \(detail)"
        case .rtfConversionFailed(let detail):
            return "Failed to convert RTF content: \(detail)"
        case .missingContent(let itemID):
            return "Could not find content for document \(itemID)."
        case .unsupportedVersion(let version):
            return "Scrivener version \(version) is not supported."
        case .fileReadFailed(let path):
            return "Failed to read file: \(path)"
        case .invalidBundleStructure(let detail):
            return "Invalid Scrivener bundle structure: \(detail)"
        case .cancelled:
            return "Import was cancelled."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notABundle:
            return "Please select a valid .scriv folder or bundle."
        case .missingProjectFile:
            return "The Scrivener project may be corrupted. Try opening it in Scrivener first."
        case .xmlParsingFailed:
            return "The project file may be corrupted. Try creating a backup in Scrivener and importing that instead."
        case .rtfConversionFailed:
            return "Some document content may not be imported correctly. You can manually copy the content from Scrivener."
        case .missingContent:
            return "The document content file may have been deleted. The document will be imported with empty content."
        case .unsupportedVersion:
            return "Please upgrade your Scrivener project to version 2.x or 3.x format."
        case .fileReadFailed:
            return "Check that you have permission to read the file and that it exists."
        case .invalidBundleStructure:
            return "The Scrivener project structure is not recognized. Try creating a backup in Scrivener."
        case .cancelled:
            return nil
        }
    }
}

/// Warnings that can occur during import (non-fatal issues)
struct ImportWarning: Identifiable {
    let id = UUID()
    let message: String
    let itemTitle: String?
    let severity: Severity

    enum Severity {
        case info
        case warning
        case error
    }

    init(message: String, itemTitle: String? = nil, severity: Severity = .warning) {
        self.message = message
        self.itemTitle = itemTitle
        self.severity = severity
    }
}

/// Result of an import operation including any warnings
struct ImportResult {
    let document: ManuscriptDocument
    let warnings: [ImportWarning]
    let skippedItems: Int
    let importedDocuments: Int
    let importedFolders: Int

    var hasWarnings: Bool {
        !warnings.isEmpty
    }

    var summary: String {
        var parts: [String] = []
        parts.append("Imported \(importedDocuments) document\(importedDocuments == 1 ? "" : "s")")
        parts.append("\(importedFolders) folder\(importedFolders == 1 ? "" : "s")")
        if skippedItems > 0 {
            parts.append("(\(skippedItems) item\(skippedItems == 1 ? "" : "s") skipped)")
        }
        return parts.joined(separator: ", ")
    }
}
