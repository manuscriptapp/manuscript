import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Exports documents to HTML format
class HTMLExporter {
    static let shared = HTMLExporter()

    private init() {}

    func export(
        documents: [CompilableDocument],
        title: String,
        author: String,
        settings: CompileSettings,
        progress: ((CompileProgress) -> Void)?
    ) async throws -> Data {
        let markdownData = try await MarkdownExporter.shared.export(
            documents: documents,
            title: title,
            author: author,
            settings: settings,
            progress: progress
        )

        guard let markdown = String(data: markdownData, encoding: .utf8) else {
            throw CompileError.exportFailed(underlying: NSError(
                domain: "HTMLExporter",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode markdown as UTF-8"]
            ))
        }

        let attributed: NSAttributedString
        do {
            let parsed = try AttributedString(markdown: markdown)
            attributed = NSAttributedString(parsed)
        } catch {
            attributed = NSAttributedString(string: markdown)
        }

        let htmlData: Data
        do {
            htmlData = try attributed.data(
                from: NSRange(location: 0, length: attributed.length),
                documentAttributes: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ]
            )
        } catch {
            throw CompileError.exportFailed(underlying: error)
        }

        let htmlBody = String(data: htmlData, encoding: .utf8) ?? ""
        let wrappedHTML = wrapHTMLBody(htmlBody, title: title, author: author)

        guard let data = wrappedHTML.data(using: .utf8) else {
            throw CompileError.exportFailed(underlying: NSError(
                domain: "HTMLExporter",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode HTML as UTF-8"]
            ))
        }

        return data
    }

    private func wrapHTMLBody(_ body: String, title: String, author: String) -> String {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "&quot;")
        let escapedAuthor = author.replacingOccurrences(of: "\"", with: "&quot;")

        return """
        <!doctype html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(escapedTitle)</title>
            <style>
                body {
                    font-family: Georgia, "Times New Roman", serif;
                    line-height: 1.6;
                    margin: 40px;
                    color: #111;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 1.6em;
                }
                hr {
                    margin: 2em 0;
                }
                .manuscript-author {
                    color: #555;
                    font-style: italic;
                    margin-bottom: 2em;
                }
            </style>
        </head>
        <body>
            <h1>\(escapedTitle)</h1>
            \(escapedAuthor.isEmpty ? "" : "<div class=\"manuscript-author\">by \(escapedAuthor)</div>")
            \(body)
        </body>
        </html>
        """
    }
}
