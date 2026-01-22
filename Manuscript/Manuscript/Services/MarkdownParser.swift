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
    /// Warm orange/amber background for comment highlights - clearly distinct from neon green
    static let commentHighlightColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.4)
    /// Darker orange for comment underline - visible against both light and dark backgrounds
    static let commentUnderlineColor = UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
    #else
    static let highlightColor = NSColor(red: 0.75, green: 1.0, blue: 0.0, alpha: 0.55)
    /// Warm orange/amber background for comment highlights - clearly distinct from neon green
    static let commentHighlightColor = NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.4)
    /// Darker orange for comment underline - visible against both light and dark backgrounds
    static let commentUnderlineColor = NSColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
    #endif

    /// Helper to compare colors with tolerance
    private static func colorsMatch(_ color1: Any, _ color2: PlatformColor) -> Bool {
        guard let c1 = color1 as? PlatformColor else { return false }

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        #if os(iOS)
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        #else
        let color1RGB = c1.usingColorSpace(.sRGB) ?? c1
        let color2RGB = color2.usingColorSpace(.sRGB) ?? color2
        color1RGB.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2RGB.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        #endif

        let tolerance: CGFloat = 0.1
        return abs(r1 - r2) < tolerance &&
               abs(g1 - g2) < tolerance &&
               abs(b1 - b2) < tolerance
    }

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

            if let bgColor = attributes[.backgroundColor] {
                // Only mark as highlight if it matches our specific highlight color
                // This prevents comment background colors from being converted to ==text==
                isHighlight = colorsMatch(bgColor, highlightColor)
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

    // MARK: - Comment Highlighting

    /// Applies comment highlighting to an attributed string
    /// - Parameters:
    ///   - attributedString: The base attributed string
    ///   - comments: Array of comment ranges to highlight
    /// - Returns: A new attributed string with comment highlights applied
    static func applyCommentHighlights(
        to attributedString: NSAttributedString,
        comments: [NSRange]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: attributedString)

        for range in comments {
            // Validate range is within bounds
            guard range.location >= 0,
                  range.location + range.length <= result.length else { continue }

            // Apply warm brown/sepia background - distinct from neon green highlight
            result.addAttribute(.backgroundColor, value: commentHighlightColor, range: range)
            // Apply thick underline to indicate commented text
            result.addAttribute(.underlineStyle, value: NSUnderlineStyle.thick.rawValue, range: range)
            result.addAttribute(.underlineColor, value: commentUnderlineColor, range: range)
            // Remove any strikethrough that might have been applied from markdown parsing
            result.removeAttribute(.strikethroughStyle, range: range)
            result.removeAttribute(.strikethroughColor, range: range)
        }

        return result
    }

    /// Creates a darker version of a color
    private static func darkenColor(_ color: PlatformColor, by amount: CGFloat) -> PlatformColor {
        #if os(iOS)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: max(0, b - amount), alpha: a)
        #else
        guard let hsbColor = color.usingColorSpace(.deviceRGB) else { return color }
        let h = hsbColor.hueComponent
        let s = hsbColor.saturationComponent
        let b = hsbColor.brightnessComponent
        let a = hsbColor.alphaComponent
        return NSColor(hue: h, saturation: s, brightness: max(0, b - amount), alpha: a)
        #endif
    }

    /// Converts a hex color string to a platform color
    static func colorFromHex(_ hex: String) -> PlatformColor? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        guard hexString.count == 6,
              let hexValue = UInt64(hexString, radix: 16) else {
            return nil
        }

        let r = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hexValue & 0x0000FF) / 255.0

        #if os(iOS)
        return UIColor(red: r, green: g, blue: b, alpha: 0.35)
        #else
        return NSColor(red: r, green: g, blue: b, alpha: 0.35)
        #endif
    }
}
