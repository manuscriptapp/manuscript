import Foundation

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

/// Converts Markdown content to RTF format for Scrivener export
final class MarkdownToRTFConverter {

    // MARK: - Singleton

    static let shared = MarkdownToRTFConverter()

    private init() {}

    // MARK: - Public Methods

    /// Converts markdown text to RTF data
    /// - Parameter markdown: The markdown string to convert
    /// - Returns: RTF data suitable for writing to a .rtf file
    func convert(_ markdown: String) -> Data {
        let attributed = parseMarkdown(markdown)

        // Generate RTF from attributed string
        do {
            let rtfData = try attributed.data(
                from: NSRange(location: 0, length: attributed.length),
                documentAttributes: [
                    .documentType: NSAttributedString.DocumentType.rtf,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ]
            )
            return rtfData
        } catch {
            // Fallback: create minimal RTF with plain text
            return createMinimalRTF(from: markdown)
        }
    }

    /// Creates an empty RTF document
    /// - Returns: RTF data for an empty document
    func createEmptyRTF() -> Data {
        createMinimalRTF(from: "")
    }

    // MARK: - Private Methods

    private func parseMarkdown(_ markdown: String) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()

        // Default font
        #if canImport(AppKit)
        let defaultFont = NSFont.systemFont(ofSize: 12)
        let boldFont = NSFont.boldSystemFont(ofSize: 12)
        let italicFont = NSFont(descriptor: defaultFont.fontDescriptor.withSymbolicTraits(.italic), size: 12) ?? defaultFont
        let boldItalicFont = NSFont(descriptor: boldFont.fontDescriptor.withSymbolicTraits(.italic), size: 12) ?? boldFont
        #else
        let defaultFont = UIFont.systemFont(ofSize: 12)
        let boldFont = UIFont.boldSystemFont(ofSize: 12)
        let italicFont = UIFont.italicSystemFont(ofSize: 12)
        let boldItalicFont = UIFont(descriptor: boldFont.fontDescriptor.withSymbolicTraits(.traitItalic)!, size: 12)
        #endif

        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont
        ]

        let lines = markdown.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            var processedLine = line
            var attributes = defaultAttributes

            // Handle headings
            if processedLine.hasPrefix("# ") {
                processedLine = String(processedLine.dropFirst(2))
                #if canImport(AppKit)
                attributes[.font] = NSFont.boldSystemFont(ofSize: 24)
                #else
                attributes[.font] = UIFont.boldSystemFont(ofSize: 24)
                #endif
            } else if processedLine.hasPrefix("## ") {
                processedLine = String(processedLine.dropFirst(3))
                #if canImport(AppKit)
                attributes[.font] = NSFont.boldSystemFont(ofSize: 18)
                #else
                attributes[.font] = UIFont.boldSystemFont(ofSize: 18)
                #endif
            } else if processedLine.hasPrefix("### ") {
                processedLine = String(processedLine.dropFirst(4))
                #if canImport(AppKit)
                attributes[.font] = NSFont.boldSystemFont(ofSize: 14)
                #else
                attributes[.font] = UIFont.boldSystemFont(ofSize: 14)
                #endif
            }

            // Parse inline formatting (bold, italic)
            let attributedLine = parseInlineFormatting(
                processedLine,
                defaultFont: defaultFont,
                boldFont: boldFont,
                italicFont: italicFont,
                boldItalicFont: boldItalicFont
            )

            // Apply heading font if this was a heading
            if attributes[.font] as? AnyObject !== defaultFont as AnyObject {
                attributedLine.addAttribute(.font, value: attributes[.font]!, range: NSRange(location: 0, length: attributedLine.length))
            }

            result.append(attributedLine)

            // Add newline between lines (except for last line)
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: defaultAttributes))
            }
        }

        return result
    }

    #if canImport(AppKit)
    private func parseInlineFormatting(
        _ text: String,
        defaultFont: NSFont,
        boldFont: NSFont,
        italicFont: NSFont,
        boldItalicFont: NSFont
    ) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            // Check for bold+italic (***text***)
            if text[currentIndex...].hasPrefix("***") {
                if let endRange = text[text.index(currentIndex, offsetBy: 3)...].range(of: "***") {
                    let contentStart = text.index(currentIndex, offsetBy: 3)
                    let content = String(text[contentStart..<endRange.lowerBound])
                    result.append(NSAttributedString(string: content, attributes: [.font: boldItalicFont]))
                    currentIndex = text.index(endRange.upperBound, offsetBy: 0)
                    continue
                }
            }

            // Check for bold (**text**)
            if text[currentIndex...].hasPrefix("**") {
                if let endRange = text[text.index(currentIndex, offsetBy: 2)...].range(of: "**") {
                    let contentStart = text.index(currentIndex, offsetBy: 2)
                    let content = String(text[contentStart..<endRange.lowerBound])
                    result.append(NSAttributedString(string: content, attributes: [.font: boldFont]))
                    currentIndex = text.index(endRange.upperBound, offsetBy: 0)
                    continue
                }
            }

            // Check for italic (*text* or _text_)
            if text[currentIndex...].hasPrefix("*") || text[currentIndex...].hasPrefix("_") {
                let marker = String(text[currentIndex])
                let searchStart = text.index(currentIndex, offsetBy: 1)
                if searchStart < text.endIndex, let endRange = text[searchStart...].range(of: marker) {
                    let content = String(text[searchStart..<endRange.lowerBound])
                    // Make sure it's not an empty match or double marker
                    if !content.isEmpty && !content.hasPrefix(marker) {
                        result.append(NSAttributedString(string: content, attributes: [.font: italicFont]))
                        currentIndex = text.index(endRange.upperBound, offsetBy: 0)
                        continue
                    }
                }
            }

            // Check for links [text](url)
            if text[currentIndex...].hasPrefix("[") {
                if let linkMatch = parseLink(from: text, startingAt: currentIndex) {
                    let linkAttributes: [NSAttributedString.Key: Any] = [
                        .font: defaultFont,
                        .link: linkMatch.url,
                        .foregroundColor: NSColor.linkColor
                    ]
                    result.append(NSAttributedString(string: linkMatch.text, attributes: linkAttributes))
                    currentIndex = linkMatch.endIndex
                    continue
                }
            }

            // Regular character
            result.append(NSAttributedString(string: String(text[currentIndex]), attributes: [.font: defaultFont]))
            currentIndex = text.index(after: currentIndex)
        }

        return result
    }
    #else
    private func parseInlineFormatting(
        _ text: String,
        defaultFont: UIFont,
        boldFont: UIFont,
        italicFont: UIFont,
        boldItalicFont: UIFont
    ) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            // Check for bold+italic (***text***)
            if text[currentIndex...].hasPrefix("***") {
                if let endRange = text[text.index(currentIndex, offsetBy: 3)...].range(of: "***") {
                    let contentStart = text.index(currentIndex, offsetBy: 3)
                    let content = String(text[contentStart..<endRange.lowerBound])
                    result.append(NSAttributedString(string: content, attributes: [.font: boldItalicFont]))
                    currentIndex = text.index(endRange.upperBound, offsetBy: 0)
                    continue
                }
            }

            // Check for bold (**text**)
            if text[currentIndex...].hasPrefix("**") {
                if let endRange = text[text.index(currentIndex, offsetBy: 2)...].range(of: "**") {
                    let contentStart = text.index(currentIndex, offsetBy: 2)
                    let content = String(text[contentStart..<endRange.lowerBound])
                    result.append(NSAttributedString(string: content, attributes: [.font: boldFont]))
                    currentIndex = text.index(endRange.upperBound, offsetBy: 0)
                    continue
                }
            }

            // Check for italic (*text* or _text_)
            if text[currentIndex...].hasPrefix("*") || text[currentIndex...].hasPrefix("_") {
                let marker = String(text[currentIndex])
                let searchStart = text.index(currentIndex, offsetBy: 1)
                if searchStart < text.endIndex, let endRange = text[searchStart...].range(of: marker) {
                    let content = String(text[searchStart..<endRange.lowerBound])
                    // Make sure it's not an empty match or double marker
                    if !content.isEmpty && !content.hasPrefix(marker) {
                        result.append(NSAttributedString(string: content, attributes: [.font: italicFont]))
                        currentIndex = text.index(endRange.upperBound, offsetBy: 0)
                        continue
                    }
                }
            }

            // Check for links [text](url)
            if text[currentIndex...].hasPrefix("[") {
                if let linkMatch = parseLink(from: text, startingAt: currentIndex) {
                    let linkAttributes: [NSAttributedString.Key: Any] = [
                        .font: defaultFont,
                        .link: linkMatch.url,
                        .foregroundColor: UIColor.link
                    ]
                    result.append(NSAttributedString(string: linkMatch.text, attributes: linkAttributes))
                    currentIndex = linkMatch.endIndex
                    continue
                }
            }

            // Regular character
            result.append(NSAttributedString(string: String(text[currentIndex]), attributes: [.font: defaultFont]))
            currentIndex = text.index(after: currentIndex)
        }

        return result
    }
    #endif

    private struct LinkMatch {
        let text: String
        let url: String
        let endIndex: String.Index
    }

    private func parseLink(from text: String, startingAt start: String.Index) -> LinkMatch? {
        // Find closing bracket
        guard let closeBracket = text[text.index(after: start)...].firstIndex(of: "]") else {
            return nil
        }

        // Check for opening parenthesis immediately after
        let afterBracket = text.index(after: closeBracket)
        guard afterBracket < text.endIndex, text[afterBracket] == "(" else {
            return nil
        }

        // Find closing parenthesis
        guard let closeParen = text[text.index(after: afterBracket)...].firstIndex(of: ")") else {
            return nil
        }

        let linkText = String(text[text.index(after: start)..<closeBracket])
        let linkURL = String(text[text.index(after: afterBracket)..<closeParen])

        return LinkMatch(text: linkText, url: linkURL, endIndex: text.index(after: closeParen))
    }

    private func createMinimalRTF(from text: String) -> Data {
        // Escape special RTF characters
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "{", with: "\\{")
            .replacingOccurrences(of: "}", with: "\\}")
            .replacingOccurrences(of: "\n", with: "\\par\n")

        // Encode unicode characters
        var rtfContent = ""
        for char in escaped {
            let scalars = char.unicodeScalars
            if let scalar = scalars.first, scalar.value > 127 {
                rtfContent += "\\u\(scalar.value)?"
            } else {
                rtfContent += String(char)
            }
        }

        let rtf = """
        {\\rtf1\\ansi\\ansicpg1252\\cocoartf2639
        {\\fonttbl\\f0\\fswiss\\fcharset0 Helvetica;}
        {\\colortbl;\\red0\\green0\\blue0;}
        \\f0\\fs24 \(rtfContent)
        }
        """

        return rtf.data(using: .utf8) ?? Data()
    }
}
