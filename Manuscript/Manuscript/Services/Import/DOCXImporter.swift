//
//  DOCXImporter.swift
//  Manuscript
//
//  Imports DOCX files into Manuscript documents using platform APIs.
//

import Foundation
import UniformTypeIdentifiers

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// DOCXImportResult is now provided by DocumentImportTypes.swift

// DOCXImportOptions is now provided by DocumentImportTypes.swift

/// Imports DOCX files into Manuscript format
final class DOCXImporter {

    // MARK: - Properties

    private let fileManager = FileManager.default
    private var warnings: [ImportWarning] = []

    // MARK: - Public Methods

    /// Validate a DOCX file before importing
    func validate(at url: URL) -> DOCXValidationResult {
        var errors: [String] = []
        var warnings: [String] = []

        // Check file exists
        guard fileManager.fileExists(atPath: url.path) else {
            return DOCXValidationResult(
                isValid: false,
                errors: ["File does not exist at \(url.lastPathComponent)"]
            )
        }

        // Check extension
        let ext = url.pathExtension.lowercased()
        guard ext == "docx" || ext == "doc" else {
            return DOCXValidationResult(
                isValid: false,
                errors: ["File is not a Word document (.docx or .doc)"]
            )
        }

        // Check file size
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                if fileSize > 50_000_000 { // 50 MB
                    warnings.append("Large file (\(fileSize / 1_000_000) MB) - import may take a while")
                }
                if fileSize == 0 {
                    errors.append("File is empty")
                }
            }
        } catch {
            warnings.append("Could not read file attributes")
        }

        // Check if .doc format (older format has limited support)
        if ext == "doc" {
            warnings.append("Older .doc format may have limited formatting support")
        }

        // Try to read the file to validate it's actually a valid DOCX
        do {
            let data = try Data(contentsOf: url)
            _ = try createAttributedString(from: data, fileExtension: ext)
        } catch {
            errors.append("Could not read document: \(error.localizedDescription)")
        }

        // Extract title from filename
        let title = url.deletingPathExtension().lastPathComponent

        return DOCXValidationResult(
            isValid: errors.isEmpty,
            documentTitle: title,
            fileSize: (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0,
            warnings: warnings,
            errors: errors
        )
    }

    /// Import a DOCX file and return a document
    func importDocument(
        from url: URL,
        options: DOCXImportOptions = .default,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> DOCXImportResult {
        warnings = []

        progress?(0.1, "Reading document...")

        // Read file data
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.fileReadFailed(url.path)
        }

        progress?(0.3, "Converting content...")

        // Convert to attributed string
        let attributedString: NSAttributedString
        let ext = url.pathExtension.lowercased()
        do {
            attributedString = try createAttributedString(from: data, fileExtension: ext)
        } catch {
            throw ImportError.rtfConversionFailed("Could not parse DOCX content: \(error.localizedDescription)")
        }

        progress?(0.6, "Extracting text...")

        // Convert to Markdown
        let markdownContent: String
        if options.preserveFormatting {
            markdownContent = convertAttributedStringToMarkdown(attributedString)
        } else {
            markdownContent = attributedString.string
        }

        progress?(0.9, "Creating document...")

        // Extract title from filename
        let title = url.deletingPathExtension().lastPathComponent

        // Create the document
        let document = ManuscriptDocument.Document(
            title: title,
            content: markdownContent,
            creationDate: Date(),
            iconName: "doc.text.fill"
        )

        progress?(1.0, "Import complete!")

        return DOCXImportResult(
            document: document,
            title: title,
            warnings: warnings
        )
    }

    /// Import multiple DOCX files
    func importDocuments(
        from urls: [URL],
        options: DOCXImportOptions = .default,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> [DOCXImportResult] {
        var results: [DOCXImportResult] = []
        let totalFiles = urls.count

        for (index, url) in urls.enumerated() {
            let fileProgress = Double(index) / Double(totalFiles)
            progress?(fileProgress, "Importing \(url.lastPathComponent)...")

            let result = try await importDocument(from: url, options: options) { subProgress, status in
                let overallProgress = fileProgress + (subProgress / Double(totalFiles))
                progress?(overallProgress, status)
            }
            results.append(result)
        }

        progress?(1.0, "All files imported!")
        return results
    }

    // MARK: - Private Methods

    private func createAttributedString(from data: Data, fileExtension: String) throws -> NSAttributedString {
        let documentType: NSAttributedString.DocumentType = fileExtension == "doc" ? .docFormat : .officeOpenXML

        #if canImport(AppKit)
        var documentAttributes: NSDictionary?
        guard let attributedString = NSAttributedString(
            docFormat: data,
            documentAttributes: &documentAttributes
        ) ?? NSAttributedString(
            data: data,
            options: [.documentType: documentType],
            documentAttributes: &documentAttributes
        ) else {
            // Try plain text as fallback
            if let plainText = String(data: data, encoding: .utf8) {
                return NSAttributedString(string: plainText)
            }
            throw ImportError.rtfConversionFailed("Could not parse document data")
        }
        return attributedString

        #elseif canImport(UIKit)
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: [.documentType: documentType],
                documentAttributes: nil
            )
            return attributedString
        } catch {
            // Try plain text as fallback
            if let plainText = String(data: data, encoding: .utf8) {
                return NSAttributedString(string: plainText)
            }
            throw ImportError.rtfConversionFailed("Could not parse document data: \(error.localizedDescription)")
        }
        #endif
    }

    private func convertAttributedStringToMarkdown(_ attrString: NSAttributedString) -> String {
        let string = attrString.string

        guard !string.isEmpty else {
            return ""
        }

        var result = ""

        // Process the attributed string by enumerating attributes
        attrString.enumerateAttributes(
            in: NSRange(location: 0, length: attrString.length),
            options: []
        ) { attributes, range, _ in
            guard let swiftRange = Range(range, in: string) else { return }

            var text = String(string[swiftRange])

            // Skip empty segments
            guard !text.isEmpty else { return }

            // Check for formatting
            var isBold = false
            var isItalic = false
            var isStrikethrough = false
            var isUnderline = false
            var linkURL: String?

            // Check font for bold/italic
            #if canImport(AppKit)
            if let font = attributes[.font] as? NSFont {
                let traits = font.fontDescriptor.symbolicTraits
                isBold = traits.contains(.bold)
                isItalic = traits.contains(.italic)
            }
            #elseif canImport(UIKit)
            if let font = attributes[.font] as? UIFont {
                let traits = font.fontDescriptor.symbolicTraits
                isBold = traits.contains(.traitBold)
                isItalic = traits.contains(.traitItalic)
            }
            #endif

            // Check for strikethrough
            if let strikethrough = attributes[.strikethroughStyle] as? Int, strikethrough != 0 {
                isStrikethrough = true
            }

            // Check for underline
            if let underline = attributes[.underlineStyle] as? Int, underline != 0 {
                isUnderline = true
            }

            // Check for links
            if let url = attributes[.link] as? URL {
                linkURL = url.absoluteString
            } else if let urlString = attributes[.link] as? String {
                linkURL = urlString
            }

            // Apply markdown formatting
            if let url = linkURL, !text.trimmingCharacters(in: .whitespaces).isEmpty {
                text = "[\(text)](\(url))"
            } else {
                // Apply text formatting only to non-whitespace content
                let leadingWhitespace = text.prefix(while: { $0.isWhitespace })
                let trailingWhitespace = text.reversed().prefix(while: { $0.isWhitespace })
                let trimmedText = text.trimmingCharacters(in: .whitespaces)

                if !trimmedText.isEmpty {
                    var formattedText = trimmedText

                    if isStrikethrough {
                        formattedText = "~~\(formattedText)~~"
                    }

                    // Underline doesn't have standard Markdown, use HTML
                    if isUnderline && !isBold && !isItalic {
                        formattedText = "<u>\(formattedText)</u>"
                    }

                    if isBold && isItalic {
                        formattedText = "***\(formattedText)***"
                    } else if isBold {
                        formattedText = "**\(formattedText)**"
                    } else if isItalic {
                        formattedText = "*\(formattedText)*"
                    }

                    text = String(leadingWhitespace) + formattedText + String(trailingWhitespace.reversed())
                }
            }

            result += text
        }

        // Post-process the markdown
        result = cleanupMarkdown(result)

        return result
    }

    private func cleanupMarkdown(_ text: String) -> String {
        var result = text

        // Normalize line endings
        result = result.replacingOccurrences(of: "\r\n", with: "\n")
        result = result.replacingOccurrences(of: "\r", with: "\n")

        // Clean up adjacent formatting markers that should be merged
        result = result.replacingOccurrences(of: "** **", with: " ")
        result = result.replacingOccurrences(of: "* *", with: " ")
        result = result.replacingOccurrences(of: "~~ ~~", with: " ")

        // Remove empty formatting markers
        result = result.replacingOccurrences(of: "******", with: "")
        result = result.replacingOccurrences(of: "****", with: "")

        // Clean up multiple spaces (but preserve paragraph breaks)
        let lines = result.components(separatedBy: "\n")
        let cleanedLines = lines.map { line -> String in
            var cleanedLine = line
            while cleanedLine.contains("  ") {
                cleanedLine = cleanedLine.replacingOccurrences(of: "  ", with: " ")
            }
            return cleanedLine
        }
        result = cleanedLines.joined(separator: "\n")

        // Trim trailing whitespace from each line
        let trimmedLines = result.components(separatedBy: "\n").map {
            $0.trimmingCharacters(in: .init(charactersIn: " \t"))
        }
        result = trimmedLines.joined(separator: "\n")

        // Collapse more than 2 consecutive newlines into 2
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// DOCXValidationResult is now provided by DocumentImportTypes.swift
