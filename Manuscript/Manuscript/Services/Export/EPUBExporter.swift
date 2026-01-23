import Foundation

/// Exports documents to EPUB format
/// EPUB is a ZIP archive containing XHTML content with metadata
class EPUBExporter {
    static let shared = EPUBExporter()

    private init() {}

    // MARK: - Export

    func export(
        documents: [CompilableDocument],
        title: String,
        author: String,
        settings: CompileSettings,
        progress: ((CompileProgress) -> Void)?
    ) async throws -> Data {
        progress?(CompileProgress(
            currentDocument: 0,
            totalDocuments: documents.count,
            currentPhase: .generating
        ))

        let bookId = UUID().uuidString

        // Build chapter files
        var chapters: [(filename: String, title: String, content: String)] = []

        // Title page
        if settings.includeTitlePage {
            let titlePageContent = buildTitlePageXHTML(title: title, author: author)
            chapters.append((filename: "title.xhtml", title: "Title Page", content: titlePageContent))
        }

        // Table of contents page
        if settings.includeTableOfContents {
            let tocContent = buildTocPageXHTML(documents: documents, settings: settings)
            chapters.append((filename: "toc-page.xhtml", title: "Table of Contents", content: tocContent))
        }

        // Content chapters
        for (index, doc) in documents.enumerated() {
            progress?(CompileProgress(
                currentDocument: index + 1,
                totalDocuments: documents.count,
                currentPhase: .processing
            ))

            let chapterContent = buildChapterXHTML(
                document: doc,
                chapterNumber: index + 1,
                settings: settings
            )
            let filename = "chapter-\(String(format: "%03d", index + 1)).xhtml"
            chapters.append((filename: filename, title: doc.title, content: chapterContent))
        }

        // Build EPUB structure
        let containerXML = buildContainerXML()
        let contentOPF = buildContentOPF(
            title: title,
            author: author,
            bookId: bookId,
            chapters: chapters
        )
        let tocNCX = buildTocNCX(
            title: title,
            bookId: bookId,
            chapters: chapters
        )
        let navXHTML = buildNavXHTML(title: title, chapters: chapters)
        let stylesCSS = buildStylesCSS(settings: settings)

        // Create ZIP archive (EPUB)
        let zipBuilder = ZipArchiveBuilder()

        // mimetype must be first and uncompressed
        try zipBuilder.addFile(path: "mimetype", content: "application/epub+zip", compress: false)

        // META-INF
        try zipBuilder.addFile(path: "META-INF/container.xml", content: containerXML)

        // OEBPS content
        try zipBuilder.addFile(path: "OEBPS/content.opf", content: contentOPF)
        try zipBuilder.addFile(path: "OEBPS/toc.ncx", content: tocNCX)
        try zipBuilder.addFile(path: "OEBPS/nav.xhtml", content: navXHTML)
        try zipBuilder.addFile(path: "OEBPS/styles.css", content: stylesCSS)

        // Chapters
        for chapter in chapters {
            try zipBuilder.addFile(path: "OEBPS/\(chapter.filename)", content: chapter.content)
        }

        let epubData = try zipBuilder.finalize()

        progress?(CompileProgress(
            currentDocument: documents.count,
            totalDocuments: documents.count,
            currentPhase: .complete
        ))

        return epubData
    }

    // MARK: - Container XML

    private func buildContainerXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
            <rootfiles>
                <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
            </rootfiles>
        </container>
        """
    }

    // MARK: - Content OPF (Package Document)

    private func buildContentOPF(
        title: String,
        author: String,
        bookId: String,
        chapters: [(filename: String, title: String, content: String)]
    ) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: Date())

        // Manifest items
        var manifestItems = """
            <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
            <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
            <item id="css" href="styles.css" media-type="text/css"/>
        """

        for (index, chapter) in chapters.enumerated() {
            manifestItems += """

                <item id="chapter-\(index)" href="\(chapter.filename)" media-type="application/xhtml+xml"/>
            """
        }

        // Spine items
        var spineItems = ""
        for index in chapters.indices {
            spineItems += """

                <itemref idref="chapter-\(index)"/>
            """
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
                <dc:identifier id="bookid">urn:uuid:\(bookId)</dc:identifier>
                <dc:title>\(escapeXML(title))</dc:title>
                <dc:creator>\(escapeXML(author))</dc:creator>
                <dc:language>en</dc:language>
                <meta property="dcterms:modified">\(dateString)</meta>
            </metadata>
            <manifest>
                \(manifestItems)
            </manifest>
            <spine toc="ncx">
                \(spineItems)
            </spine>
        </package>
        """
    }

    // MARK: - TOC NCX (EPUB 2 Navigation)

    private func buildTocNCX(
        title: String,
        bookId: String,
        chapters: [(filename: String, title: String, content: String)]
    ) -> String {
        var navPoints = ""
        for (index, chapter) in chapters.enumerated() {
            navPoints += """

                <navPoint id="navpoint-\(index + 1)" playOrder="\(index + 1)">
                    <navLabel>
                        <text>\(escapeXML(chapter.title))</text>
                    </navLabel>
                    <content src="\(chapter.filename)"/>
                </navPoint>
            """
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
            <head>
                <meta name="dtb:uid" content="urn:uuid:\(bookId)"/>
                <meta name="dtb:depth" content="1"/>
                <meta name="dtb:totalPageCount" content="0"/>
                <meta name="dtb:maxPageNumber" content="0"/>
            </head>
            <docTitle>
                <text>\(escapeXML(title))</text>
            </docTitle>
            <navMap>
                \(navPoints)
            </navMap>
        </ncx>
        """
    }

    // MARK: - Nav XHTML (EPUB 3 Navigation)

    private func buildNavXHTML(
        title: String,
        chapters: [(filename: String, title: String, content: String)]
    ) -> String {
        var tocItems = ""
        for chapter in chapters {
            tocItems += """

                        <li><a href="\(chapter.filename)">\(escapeXML(chapter.title))</a></li>
            """
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
        <head>
            <meta charset="UTF-8"/>
            <title>\(escapeXML(title))</title>
            <link rel="stylesheet" type="text/css" href="styles.css"/>
        </head>
        <body>
            <nav epub:type="toc" id="toc">
                <h1>Table of Contents</h1>
                <ol>
                    \(tocItems)
                </ol>
            </nav>
        </body>
        </html>
        """
    }

    // MARK: - Styles CSS

    private func buildStylesCSS(settings: CompileSettings) -> String {
        let fontFamily: String
        switch settings.fontStyle {
        case .serif:
            fontFamily = "Georgia, 'Times New Roman', serif"
        case .sansSerif:
            fontFamily = "'Helvetica Neue', Helvetica, Arial, sans-serif"
        case .monospace:
            fontFamily = "Menlo, Monaco, 'Courier New', monospace"
        }

        return """
        body {
            font-family: \(fontFamily);
            font-size: \(Int(settings.fontSize))pt;
            line-height: \(settings.lineSpacing);
            margin: 1em;
            text-align: justify;
        }

        h1 {
            font-size: 2em;
            font-weight: bold;
            margin-top: 1em;
            margin-bottom: 0.5em;
            text-align: left;
        }

        h2 {
            font-size: 1.5em;
            font-weight: bold;
            margin-top: 1em;
            margin-bottom: 0.5em;
        }

        p {
            margin: 0.5em 0;
            text-indent: 1.5em;
        }

        p.first, h1 + p, h2 + p {
            text-indent: 0;
        }

        .title-page {
            text-align: center;
            margin-top: 30%;
        }

        .title-page h1 {
            font-size: 2.5em;
            text-align: center;
        }

        .title-page .author {
            font-size: 1.2em;
            font-style: italic;
            color: #666;
            margin-top: 1em;
        }

        .separator {
            text-align: center;
            margin: 2em 0;
        }

        nav ol {
            list-style-type: none;
            padding-left: 0;
        }

        nav li {
            margin: 0.5em 0;
        }

        nav a {
            text-decoration: none;
            color: #333;
        }
        """
    }

    // MARK: - Chapter XHTML

    private func buildTitlePageXHTML(title: String, author: String) -> String {
        var authorSection = ""
        if !author.isEmpty {
            authorSection = "<p class=\"author\">by \(escapeXML(author))</p>"
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta charset="UTF-8"/>
            <title>\(escapeXML(title))</title>
            <link rel="stylesheet" type="text/css" href="styles.css"/>
        </head>
        <body>
            <div class="title-page">
                <h1>\(escapeXML(title))</h1>
                \(authorSection)
            </div>
        </body>
        </html>
        """
    }

    private func buildTocPageXHTML(
        documents: [CompilableDocument],
        settings: CompileSettings
    ) -> String {
        var tocItems = ""
        for (index, doc) in documents.enumerated() {
            let indent = doc.depth > 0 ? "style=\"margin-left: \(doc.depth * 20)px\"" : ""
            let chapterFile = "chapter-\(String(format: "%03d", index + 1)).xhtml"
            tocItems += "<p \(indent)><a href=\"\(chapterFile)\">\(escapeXML(doc.title))</a></p>\n"
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta charset="UTF-8"/>
            <title>Table of Contents</title>
            <link rel="stylesheet" type="text/css" href="styles.css"/>
        </head>
        <body>
            <h1>Table of Contents</h1>
            \(tocItems)
        </body>
        </html>
        """
    }

    private func buildChapterXHTML(
        document: CompilableDocument,
        chapterNumber: Int,
        settings: CompileSettings
    ) -> String {
        var content = ""

        // Chapter heading
        if settings.includeChapterTitles && !document.title.isEmpty {
            let headingLevel = document.depth == 0 ? "h1" : "h2"
            content += "<\(headingLevel)>\(escapeXML(document.title))</\(headingLevel)>\n"
        }

        // Convert content to paragraphs
        let paragraphs = document.content.components(separatedBy: "\n\n")
        var isFirst = true
        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                // Handle single line breaks as <br/> within paragraphs
                let htmlContent = trimmed
                    .replacingOccurrences(of: "\n", with: "<br/>")

                let className = isFirst ? " class=\"first\"" : ""
                content += "<p\(className)>\(escapeXML(htmlContent))</p>\n"
                isFirst = false
            }
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta charset="UTF-8"/>
            <title>\(escapeXML(document.title))</title>
            <link rel="stylesheet" type="text/css" href="styles.css"/>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }

    // MARK: - Helpers

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
