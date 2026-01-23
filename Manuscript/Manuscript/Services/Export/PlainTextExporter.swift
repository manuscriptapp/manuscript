import Foundation

/// Exports documents to plain text format
class PlainTextExporter {
    static let shared = PlainTextExporter()

    private init() {}

    // MARK: - Export

    func export(
        documents: [CompilableDocument],
        title: String,
        author: String,
        settings: CompileSettings,
        progress: ((CompileProgress) -> Void)?
    ) async throws -> Data {
        var text = ""

        // Title
        text += title.uppercased()
        text += "\n"
        text += String(repeating: "=", count: title.count)
        text += "\n\n"

        // Author
        if !author.isEmpty {
            text += "by \(author)\n\n"
        }

        // Table of Contents
        if settings.includeTableOfContents {
            text += "TABLE OF CONTENTS\n"
            text += "-----------------\n\n"
            for doc in documents {
                let indent = String(repeating: "  ", count: doc.depth)
                text += "\(indent)• \(doc.title)\n"
            }
            text += "\n"
            text += String(repeating: "-", count: 40)
            text += "\n\n"
        }

        // Content
        for (index, doc) in documents.enumerated() {
            progress?(CompileProgress(
                currentDocument: index + 1,
                totalDocuments: documents.count,
                currentPhase: .processing
            ))

            // Chapter heading
            if settings.includeChapterTitles && !doc.title.isEmpty {
                text += doc.title.uppercased()
                text += "\n"
                text += String(repeating: "-", count: doc.title.count)
                text += "\n\n"
            }

            // Content - strip any markdown formatting
            let content = stripMarkdownFormatting(doc.content.trimmingCharacters(in: .whitespacesAndNewlines))
            if !content.isEmpty {
                text += content
                text += "\n"
            }

            // Separator
            if index < documents.count - 1 {
                switch settings.documentSeparator {
                case .none:
                    text += "\n\n"
                case .blankLine:
                    text += "\n\n\n"
                case .threeAsterisks:
                    text += "\n\n* * *\n\n"
                case .pageBreak:
                    text += "\n\n" + String(repeating: "-", count: 40) + "\n\n"
                case .chapterHeading:
                    text += "\n\n"
                }
            }
        }

        progress?(CompileProgress(
            currentDocument: documents.count,
            totalDocuments: documents.count,
            currentPhase: .generating
        ))

        guard let data = text.data(using: .utf8) else {
            throw CompileError.exportFailed(underlying: NSError(
                domain: "PlainTextExporter",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode text as UTF-8"]
            ))
        }

        return data
    }

    // MARK: - Markdown Stripping

    /// Removes common markdown formatting from text
    private func stripMarkdownFormatting(_ text: String) -> String {
        var result = text

        // Remove bold/italic markers
        result = result.replacingOccurrences(of: "***", with: "")
        result = result.replacingOccurrences(of: "**", with: "")
        result = result.replacingOccurrences(of: "__", with: "")
        result = result.replacingOccurrences(of: "*", with: "")
        result = result.replacingOccurrences(of: "_", with: " ")

        // Remove inline code
        result = result.replacingOccurrences(of: "`", with: "")

        // Remove links but keep text [text](url) -> text
        let linkPattern = #"\[([^\]]+)\]\([^)]+\)"#
        if let regex = try? NSRegularExpression(pattern: linkPattern) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                range: range,
                withTemplate: "$1"
            )
        }

        // Remove headers but keep text
        let lines = result.components(separatedBy: .newlines)
        result = lines.map { line in
            if line.hasPrefix("#") {
                return line.drop(while: { $0 == "#" || $0 == " " }).description
            }
            return line
        }.joined(separator: "\n")

        return result
    }
}
