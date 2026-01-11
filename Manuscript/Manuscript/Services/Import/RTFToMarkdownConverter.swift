import Foundation

#if canImport(AppKit)
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#endif

/// Converts RTF data to Markdown text
final class RTFToMarkdownConverter {

    // MARK: - Public Methods

    /// Convert RTF data to Markdown string
    /// - Parameter rtfData: RTF data to convert
    /// - Returns: Markdown string
    func convert(rtfData: Data) throws -> String {
        let attributedString = try createAttributedString(from: rtfData)
        return convertAttributedStringToMarkdown(attributedString)
    }

    /// Convert RTF file at URL to Markdown string
    /// - Parameter url: URL to RTF file
    /// - Returns: Markdown string
    func convert(rtfURL url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return try convert(rtfData: data)
    }

    /// Convert plain text file to string (for synopsis files)
    /// - Parameter url: URL to text file
    /// - Returns: Plain text string
    func convertPlainText(from url: URL) throws -> String {
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Private Methods

    private func createAttributedString(from data: Data) throws -> NSAttributedString {
        #if canImport(AppKit)
        if let attributedString = NSAttributedString(rtf: data, documentAttributes: nil) {
            return attributedString
        }
        // Try as plain text fallback
        if let plainText = String(data: data, encoding: .utf8) {
            return NSAttributedString(string: plainText)
        }
        throw ImportError.rtfConversionFailed("Could not parse RTF data")

        #elseif canImport(UIKit)
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
            return attributedString
        } catch {
            // Try as plain text fallback
            if let plainText = String(data: data, encoding: .utf8) {
                return NSAttributedString(string: plainText)
            }
            throw ImportError.rtfConversionFailed("Could not parse RTF data: \(error.localizedDescription)")
        }
        #endif
    }

    private func convertAttributedStringToMarkdown(_ attrString: NSAttributedString) -> String {
        let string = attrString.string

        guard !string.isEmpty else {
            return ""
        }

        var result = ""
        var lastIndex = string.startIndex

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
            if let strikethrough = attributes[.strikethroughStyle] as? Int,
               strikethrough != 0 {
                isStrikethrough = true
            }

            // Check for links
            if let url = attributes[.link] as? URL {
                linkURL = url.absoluteString
            } else if let urlString = attributes[.link] as? String {
                linkURL = urlString
            }

            // Apply markdown formatting
            // Note: We need to handle formatting carefully to avoid issues with whitespace

            // Handle links
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
            lastIndex = swiftRange.upperBound
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
        // e.g., **word** **another** → **word another** (when separated by just a space)
        result = result.replacingOccurrences(of: "** **", with: " ")
        result = result.replacingOccurrences(of: "* *", with: " ")
        result = result.replacingOccurrences(of: "~~ ~~", with: " ")

        // Remove empty formatting markers
        result = result.replacingOccurrences(of: "******", with: "")
        result = result.replacingOccurrences(of: "****", with: "")
        result = result.replacingOccurrences(of: "~~", with: "", options: [], range: nil)
        // Be careful not to remove valid ** or * markers

        // Clean up multiple spaces (but preserve paragraph breaks)
        let lines = result.components(separatedBy: "\n")
        let cleanedLines = lines.map { line -> String in
            // Collapse multiple spaces into single space within each line
            var cleanedLine = line
            while cleanedLine.contains("  ") {
                cleanedLine = cleanedLine.replacingOccurrences(of: "  ", with: " ")
            }
            return cleanedLine
        }
        result = cleanedLines.joined(separator: "\n")

        // Trim trailing whitespace from each line
        let trimmedLines = result.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .init(charactersIn: " \t")) }
        result = trimmedLines.joined(separator: "\n")

        // Collapse more than 2 consecutive newlines into 2
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
