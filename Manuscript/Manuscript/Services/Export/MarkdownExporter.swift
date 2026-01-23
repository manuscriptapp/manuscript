import Foundation

/// Exports documents to Markdown format with optional frontmatter and TOC
class MarkdownExporter {
    static let shared = MarkdownExporter()

    private init() {}

    // MARK: - Export

    func export(
        documents: [CompilableDocument],
        title: String,
        author: String,
        settings: CompileSettings,
        progress: ((CompileProgress) -> Void)?
    ) async throws -> Data {
        var markdown = ""

        // YAML frontmatter
        if settings.includeFrontMatter {
            markdown += "---\n"
            markdown += "title: \"\(escapeYAML(title))\"\n"
            if !author.isEmpty {
                markdown += "author: \"\(escapeYAML(author))\"\n"
            }
            markdown += "date: \"\(formattedDate())\"\n"
            markdown += "---\n\n"
        }

        // Title
        markdown += "# \(title)\n\n"

        if !author.isEmpty {
            markdown += "*by \(author)*\n\n"
        }

        // Table of Contents
        if settings.includeTableOfContents {
            markdown += "## Table of Contents\n\n"
            for doc in documents {
                let indent = String(repeating: "  ", count: doc.depth)
                let anchor = doc.title.lowercased()
                    .replacingOccurrences(of: " ", with: "-")
                    .filter { $0.isLetter || $0.isNumber || $0 == "-" }
                markdown += "\(indent)- [\(doc.title)](#\(anchor))\n"
            }
            markdown += "\n---\n\n"
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
                let headingLevel = min(doc.depth + 2, 6)  // ## for root, ### for subfolder, etc.
                let heading = String(repeating: "#", count: headingLevel)
                markdown += "\(heading) \(doc.title)\n\n"
            }

            // Content
            let content = doc.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                markdown += content
                markdown += "\n"
            }

            // Separator
            if index < documents.count - 1 {
                markdown += settings.documentSeparator.markdownSeparator
                if settings.documentSeparator == .chapterHeading {
                    markdown += "\n"
                }
            }
        }

        progress?(CompileProgress(
            currentDocument: documents.count,
            totalDocuments: documents.count,
            currentPhase: .generating
        ))

        guard let data = markdown.data(using: .utf8) else {
            throw CompileError.exportFailed(underlying: NSError(
                domain: "MarkdownExporter",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode markdown as UTF-8"]
            ))
        }

        return data
    }

    // MARK: - Helpers

    private func escapeYAML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
