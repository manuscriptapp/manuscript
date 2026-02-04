import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Imports HTML files into Manuscript documents
final class HTMLImporter {
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
        guard ext == "html" || ext == "htm" else {
            return DocumentValidationResult(
                isValid: false,
                errors: ["File is not an HTML document (.html or .htm)"]
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

        // Basic validation: can we decode as text?
        do {
            _ = try Data(contentsOf: url)
        } catch {
            errors.append("Could not read HTML file")
        }

        let title = url.deletingPathExtension().lastPathComponent

        return DocumentValidationResult(
            isValid: errors.isEmpty,
            documentTitle: title,
            fileSize: (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0,
            warnings: warnings,
            errors: errors
        )
    }

    func importDocument(
        from url: URL,
        options: DocumentImportOptions = .default,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> DocumentImportResult {
        progress?(0.1, "Reading HTML...")

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.fileReadFailed(url.path)
        }

        progress?(0.4, "Parsing HTML...")

        let attributedString: NSAttributedString
        do {
            attributedString = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
        } catch {
            throw ImportError.rtfConversionFailed("Could not parse HTML content: \(error.localizedDescription)")
        }

        progress?(0.7, "Converting content...")

        let content: String
        if options.preserveFormatting {
            content = MarkdownParser.markdown(from: attributedString)
        } else {
            content = attributedString.string
        }

        let title = url.deletingPathExtension().lastPathComponent
        let document = ManuscriptDocument.Document(
            title: title,
            content: content,
            creationDate: Date(),
            iconName: "doc.text.fill"
        )

        progress?(1.0, "Import complete!")

        var warnings: [ImportWarning] = []
        if options.preserveFormatting {
            warnings.append(
                ImportWarning(
                    message: "HTML formatting is converted to basic Markdown (bold, italic, etc.).",
                    severity: .info
                )
            )
        }

        return DocumentImportResult(
            document: document,
            title: title,
            warnings: warnings
        )
    }
}
