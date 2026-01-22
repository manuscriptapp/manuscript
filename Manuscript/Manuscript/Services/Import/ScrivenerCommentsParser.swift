import Foundation

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Parser for Scrivener's content.comments XML files
/// Format:
/// ```xml
/// <Comments>
///     <Comment ID="UUID" Color="R G B">
///         <![CDATA[RTF content]]>
///     </Comment>
/// </Comments>
/// ```
class ScrivenerCommentsParser: NSObject, XMLParserDelegate {
    private var comments: [ManuscriptDocument.DocumentComment] = []
    private var currentCommentID: String?
    private var currentCommentColor: String?
    private var currentCommentText: String = ""
    private var rtfConverter: RTFToMarkdownConverter?

    func parse(data: Data, rtfConverter: RTFToMarkdownConverter) throws -> [ManuscriptDocument.DocumentComment] {
        self.rtfConverter = rtfConverter
        comments = []

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        return comments
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "Comment" {
            currentCommentID = attributeDict["ID"]
            currentCommentColor = attributeDict["Color"]
            currentCommentText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentCommentText += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        // The CDATA block contains RTF content
        if let rtfString = String(data: CDATABlock, encoding: .utf8) {
            // Convert RTF to markdown
            if let converter = rtfConverter,
               let markdown = try? converter.convertRTFString(rtfString) {
                currentCommentText = markdown
            } else {
                // Fallback: extract plain text from RTF
                currentCommentText = extractPlainTextFromRTF(rtfString)
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Comment" {
            let comment = ManuscriptDocument.DocumentComment(
                id: UUID(uuidString: currentCommentID ?? "") ?? UUID(),
                text: currentCommentText.trimmingCharacters(in: .whitespacesAndNewlines),
                color: parseScrivenerColor(currentCommentColor),
                range: nil,
                creationDate: Date()
            )
            comments.append(comment)
            currentCommentID = nil
            currentCommentColor = nil
            currentCommentText = ""
        }
    }

    /// Convert Scrivener's "R G B" color format to hex
    private func parseScrivenerColor(_ colorString: String?) -> String {
        guard let colorString = colorString else { return "#FFFF00" }

        let components = colorString.split(separator: " ").compactMap { Double($0) }
        guard components.count >= 3 else { return "#FFFF00" }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// Extract plain text from RTF as fallback
    private func extractPlainTextFromRTF(_ rtfString: String) -> String {
        // Simple extraction - remove RTF control words
        var result = rtfString

        // Remove RTF header and control words
        if let range = result.range(of: "\\pard", options: .literal) {
            result = String(result[range.upperBound...])
        }

        // Remove common control sequences
        let patterns = [
            "\\\\[a-z]+[0-9]*\\s?",  // Control words like \f0, \fs24
            "\\{[^}]*\\}",            // Braced groups
            "\\\\",                    // Escaped backslashes
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: NSRange(location: 0, length: result.utf16.count),
                    withTemplate: ""
                )
            }
        }

        // Remove remaining braces
        result = result.replacingOccurrences(of: "{", with: "")
        result = result.replacingOccurrences(of: "}", with: "")

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

