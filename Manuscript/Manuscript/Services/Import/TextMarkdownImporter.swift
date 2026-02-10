import Foundation

/// Imports Markdown and plain text files into Manuscript documents.
final class TextMarkdownImporter {
    private let fileManager = FileManager.default

    func validate(at url: URL) -> DocumentValidationResult {
        var errors: [String] = []
        var warnings: [String] = []

        guard fileManager.fileExists(atPath: url.path) else {
            return DocumentValidationResult(
                isValid: false,
                errors: ["File does not exist at \(url.lastPathComponent)"]
            )
        }

        let ext = url.pathExtension.lowercased()
        guard ["md", "markdown", "txt"].contains(ext) else {
            return DocumentValidationResult(
                isValid: false,
                errors: ["File is not a supported text or markdown document (.md, .markdown, .txt)"]
            )
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                if fileSize > 10_000_000 {
                    warnings.append("Large file (\(fileSize / 1_000_000) MB) - import may take a while")
                }
                if fileSize == 0 {
                    errors.append("File is empty")
                }
            }
        } catch {
            warnings.append("Could not read file attributes")
        }

        do {
            _ = try readText(from: url)
        } catch {
            errors.append("Could not read text content: \(error.localizedDescription)")
        }

        let title = url.deletingPathExtension().lastPathComponent
        let fileSize = (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

        return DocumentValidationResult(
            isValid: errors.isEmpty,
            documentTitle: title,
            fileSize: fileSize,
            warnings: warnings,
            errors: errors
        )
    }

    func importDocument(
        from url: URL,
        options: DocumentImportOptions = .default,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> DocumentImportResult {
        progress?(0.1, "Reading document...")

        let ext = url.pathExtension.lowercased()
        let rawText: String
        do {
            rawText = try readText(from: url)
        } catch {
            throw ImportError.fileReadFailed(url.path)
        }

        progress?(0.6, "Converting content...")

        let content: String
        var warnings: [ImportWarning] = []
        if options.preserveFormatting || ext == "txt" {
            content = rawText
        } else {
            // Markdown can be flattened to plain text when formatting is disabled.
            if let attributed = try? AttributedString(markdown: rawText) {
                content = String(attributed.characters)
            } else {
                content = rawText
                warnings.append(
                    ImportWarning(
                        message: "Could not flatten Markdown formatting cleanly. Imported as raw text.",
                        severity: .info
                    )
                )
            }
        }

        if (ext == "md" || ext == "markdown") && options.preserveFormatting {
            warnings.append(
                ImportWarning(
                    message: "Markdown syntax is preserved as editable text content.",
                    severity: .info
                )
            )
        }

        progress?(0.9, "Creating document...")

        let title = url.deletingPathExtension().lastPathComponent
        let document = ManuscriptDocument.Document(
            title: title,
            content: content,
            creationDate: Date(),
            iconName: "doc.text.fill"
        )

        progress?(1.0, "Import complete!")

        return DocumentImportResult(
            document: document,
            title: title,
            warnings: warnings
        )
    }

    private func readText(from url: URL) throws -> String {
        var encoding = String.Encoding.utf8
        return try String(contentsOf: url, usedEncoding: &encoding)
    }
}
