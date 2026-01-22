import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Service for converting between Markdown and NSAttributedString
/// Supports bold, italic, strikethrough, highlight, and basic formatting
enum MarkdownParser {

    /// Neon highlight color (bright chartreuse/neon green-yellow)
    #if os(iOS)
    static let highlightColor = UIColor(red: 0.75, green: 1.0, blue: 0.0, alpha: 0.55)
    #else
    static let highlightColor = NSColor(red: 0.75, green: 1.0, blue: 0.0, alpha: 0.55)
    #endif

    // MARK: - Markdown to Attributed String

    /// Converts Markdown text to an NSAttributedString with formatting
    /// - Parameters:
    ///   - markdown: The markdown string to parse
    ///   - baseFont: The base font to use (formatting will derive from this)
    ///   - textColor: The text color to use
    /// - Returns: An attributed string with the markdown formatting applied
    static func attributedString(
        from markdown: String,
        baseFont: PlatformFont,
        textColor: PlatformColor
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Base attributes
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: textColor
        ]

        // Process markdown line by line to handle paragraphs
        let lines = markdown.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            let processedLine = processInlineFormatting(line, baseFont: baseFont, textColor: textColor)
            result.append(processedLine)

            // Add newline between lines (except for the last one)
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: baseAttributes))
            }
        }

        return result
    }

    /// Process inline formatting (bold, italic, strikethrough) in a single line
    private static func processInlineFormatting(
        _ text: String,
        baseFont: PlatformFont,
        textColor: PlatformColor
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Regex patterns for markdown formatting
        // Order matters: process bold+italic first, then bold, then italic, then strikethrough, then highlight
        let patterns: [(pattern: String, style: MarkdownStyle)] = [
            ("\\*\\*\\*(.+?)\\*\\*\\*", .boldItalic),     // ***bold italic***
            ("___(.+?)___", .boldItalic),                  // ___bold italic___
            ("\\*\\*(.+?)\\*\\*", .bold),                  // **bold**
            ("__(.+?)__", .bold),                          // __bold__
            ("\\*(.+?)\\*", .italic),                      // *italic*
            ("_(.+?)_", .italic),                          // _italic_
            ("~~(.+?)~~", .strikethrough),                 // ~~strikethrough~~
            ("==(.+?)==", .highlight),                     // ==highlight==
        ]

        let processedText = text
        var formattingRanges: [(range: Range<String.Index>, style: MarkdownStyle, content: String)] = []

        // Find all formatting ranges
        for (pattern, style) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }

            let nsRange = NSRange(processedText.startIndex..., in: processedText)
            let matches = regex.matches(in: processedText, options: [], range: nsRange)

            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: processedText),
                      let contentRange = Range(match.range(at: 1), in: processedText) else { continue }

                let content = String(processedText[contentRange])
                formattingRanges.append((fullRange, style, content))
            }
        }

        // Sort ranges by start position
        formattingRanges.sort { $0.range.lowerBound < $1.range.lowerBound }

        // Remove overlapping ranges (keep the first one found)
        var nonOverlappingRanges: [(range: Range<String.Index>, style: MarkdownStyle, content: String)] = []
        for range in formattingRanges {
            let overlaps = nonOverlappingRanges.contains { existing in
                existing.range.overlaps(range.range)
            }
            if !overlaps {
                nonOverlappingRanges.append(range)
            }
        }

        // Build the attributed string
        var currentIndex = processedText.startIndex
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: textColor
        ]

        for (range, style, content) in nonOverlappingRanges {
            // Add text before this formatting
            if currentIndex < range.lowerBound {
                let plainText = String(processedText[currentIndex..<range.lowerBound])
                result.append(NSAttributedString(string: plainText, attributes: baseAttributes))
            }

            // Add formatted text
            var attributes = baseAttributes
            attributes[.font] = fontForStyle(style, baseFont: baseFont)
            if style == .strikethrough {
                attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }
            if style == .highlight {
                attributes[.backgroundColor] = highlightColor
            }
            result.append(NSAttributedString(string: content, attributes: attributes))

            currentIndex = range.upperBound
        }

        // Add remaining text
        if currentIndex < processedText.endIndex {
            let remainingText = String(processedText[currentIndex...])
            result.append(NSAttributedString(string: remainingText, attributes: baseAttributes))
        }

        return result
    }

    private enum MarkdownStyle {
        case bold
        case italic
        case boldItalic
        case strikethrough
        case highlight
    }

    private static func fontForStyle(_ style: MarkdownStyle, baseFont: PlatformFont) -> PlatformFont {
        let fontSize = baseFont.pointSize
        let fontName = baseFont.familyName ?? "Palatino"

        switch style {
        case .bold:
            return derivedFont(name: fontName, size: fontSize, bold: true, italic: false) ?? baseFont
        case .italic:
            return derivedFont(name: fontName, size: fontSize, bold: false, italic: true) ?? baseFont
        case .boldItalic:
            return derivedFont(name: fontName, size: fontSize, bold: true, italic: true) ?? baseFont
        case .strikethrough:
            return baseFont
        case .highlight:
            return baseFont
        }
    }

    #if os(iOS)
    private static func derivedFont(name: String, size: CGFloat, bold: Bool, italic: Bool) -> UIFont? {
        var traits: UIFontDescriptor.SymbolicTraits = []
        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }

        if let baseFont = UIFont(name: name, size: size),
           let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: size)
        }

        // Fallback to system font
        var systemTraits: UIFontDescriptor.SymbolicTraits = []
        if bold { systemTraits.insert(.traitBold) }
        if italic { systemTraits.insert(.traitItalic) }

        let systemFont = UIFont.systemFont(ofSize: size)
        if let descriptor = systemFont.fontDescriptor.withSymbolicTraits(systemTraits) {
            return UIFont(descriptor: descriptor, size: size)
        }

        return nil
    }
    #else
    private static func derivedFont(name: String, size: CGFloat, bold: Bool, italic: Bool) -> NSFont? {
        let fontManager = NSFontManager.shared
        var font = NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)

        if bold {
            font = fontManager.convert(font, toHaveTrait: .boldFontMask)
        }
        if italic {
            font = fontManager.convert(font, toHaveTrait: .italicFontMask)
        }

        return font
    }
    #endif

    // MARK: - Attributed String to Markdown

    /// Converts an NSAttributedString back to Markdown format
    /// - Parameter attributedString: The attributed string to convert
    /// - Returns: A markdown string representation
    static func markdown(from attributedString: NSAttributedString) -> String {
        var result = ""
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            let text = attributedString.attributedSubstring(from: range).string

            // Skip empty strings
            guard !text.isEmpty else { return }

            // Check for formatting
            var isBold = false
            var isItalic = false
            var isStrikethrough = false
            var isHighlight = false

            if let font = attributes[.font] as? PlatformFont {
                #if os(iOS)
                let traits = font.fontDescriptor.symbolicTraits
                isBold = traits.contains(.traitBold)
                isItalic = traits.contains(.traitItalic)
                #else
                let traits = font.fontDescriptor.symbolicTraits
                isBold = traits.contains(.bold)
                isItalic = traits.contains(.italic)
                #endif
            }

            if let strikethrough = attributes[.strikethroughStyle] as? Int,
               strikethrough != 0 {
                isStrikethrough = true
            }

            if attributes[.backgroundColor] != nil {
                isHighlight = true
            }

            // Apply markdown formatting
            var formattedText = text

            // Handle newlines specially - don't wrap them in formatting
            let lines = formattedText.components(separatedBy: "\n")
            var formattedLines: [String] = []

            for line in lines {
                var formattedLine = line

                if !formattedLine.isEmpty {
                    if isHighlight {
                        formattedLine = "==\(formattedLine)=="
                    }
                    if isStrikethrough {
                        formattedLine = "~~\(formattedLine)~~"
                    }
                    if isBold && isItalic {
                        formattedLine = "***\(formattedLine)***"
                    } else if isBold {
                        formattedLine = "**\(formattedLine)**"
                    } else if isItalic {
                        formattedLine = "*\(formattedLine)*"
                    }
                }

                formattedLines.append(formattedLine)
            }

            result += formattedLines.joined(separator: "\n")
        }

        // Clean up redundant formatting (e.g., **text****more** -> **textmore**)
        result = cleanupMarkdown(result)

        return result
    }

    /// Cleans up redundant markdown formatting
    private static func cleanupMarkdown(_ markdown: String) -> String {
        var result = markdown

        // Remove empty formatting markers
        result = result.replacingOccurrences(of: "****", with: "")
        result = result.replacingOccurrences(of: "**", with: "**", options: [], range: nil)
        result = result.replacingOccurrences(of: "~~****~~", with: "")
        result = result.replacingOccurrences(of: "~~~~~~", with: "")
        result = result.replacingOccurrences(of: "====", with: "")

        // Merge adjacent same formatting: **a****b** -> **ab**
        let patterns = [
            ("\\*\\*\\*(.+?)\\*\\*\\*\\*\\*\\*(.+?)\\*\\*\\*", "***$1$2***"),
            ("\\*\\*(.+?)\\*\\*\\*\\*(.+?)\\*\\*", "**$1$2**"),
            ("\\*(.+?)\\*\\*(.+?)\\*", "*$1$2*"),
            ("~~(.+?)~~~~(.+?)~~", "~~$1$2~~"),
            ("==(.+?)====(.+?)==", "==$1$2=="),
        ]

        for (pattern, replacement) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: replacement)
            }
        }

        return result
    }
}
