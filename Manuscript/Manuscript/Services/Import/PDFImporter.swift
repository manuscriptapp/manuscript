import Foundation
#if canImport(PDFKit)
import PDFKit
#endif

/// Imports PDF files into Manuscript documents
final class PDFImporter {
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
        guard ext == "pdf" else {
            return DocumentValidationResult(
                isValid: false,
                errors: ["File is not a PDF document (.pdf)"]
            )
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                if fileSize > 50_000_000 {
                    warnings.append("Large file (\(fileSize / 1_000_000) MB) - import may take a while")
                }
                if fileSize == 0 {
                    errors.append("File is empty")
                }
            }
        } catch {
            warnings.append("Could not read file attributes")
        }

        #if canImport(PDFKit)
        if PDFDocument(url: url) == nil {
            errors.append("Could not read PDF document")
        }
        #else
        errors.append("PDF import is not available on this platform")
        #endif

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
        progress?(0.1, "Reading PDF...")

        #if canImport(PDFKit)
        guard let pdfDocument = PDFDocument(url: url) else {
            throw ImportError.fileReadFailed(url.path)
        }

        progress?(0.4, "Extracting text...")

        var warnings: [ImportWarning] = []
        var extractedPages: [String] = []

        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
               !pageText.isEmpty {
                extractedPages.append(pageText)
            } else {
                warnings.append(
                    ImportWarning(
                        message: "Page \(pageIndex + 1) contained no extractable text.",
                        severity: .info
                    )
                )
            }
        }

        if options.preserveFormatting {
            warnings.append(
                ImportWarning(
                    message: "PDF formatting cannot be fully preserved. Imported as plain text.",
                    severity: .info
                )
            )
        }

        let content = extractedPages.joined(separator: "\n\n")

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
        #else
        throw ImportError.rtfConversionFailed("PDF import is not available on this platform")
        #endif
    }
}
