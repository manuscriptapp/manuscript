import Foundation
import Compression

/// Exports documents to DOCX (Word) format
/// DOCX is a ZIP archive containing XML files following Office Open XML (OOXML) standard
class DocXExporter {
    static let shared = DocXExporter()

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

        // Build the document XML content
        let documentXML = buildDocumentXML(
            documents: documents,
            title: title,
            author: author,
            settings: settings,
            progress: progress
        )

        // Build other required XML files
        let contentTypesXML = buildContentTypesXML()
        let relsXML = buildRelsXML()
        let documentRelsXML = buildDocumentRelsXML()
        let stylesXML = buildStylesXML(settings: settings)
        let corePropsXML = buildCorePropertiesXML(title: title, author: author)
        let appPropsXML = buildAppPropertiesXML()

        // Create ZIP archive
        let zipData = try createDocxZip(
            contentTypes: contentTypesXML,
            rels: relsXML,
            documentRels: documentRelsXML,
            document: documentXML,
            styles: stylesXML,
            coreProps: corePropsXML,
            appProps: appPropsXML
        )

        progress?(CompileProgress(
            currentDocument: documents.count,
            totalDocuments: documents.count,
            currentPhase: .complete
        ))

        return zipData
    }

    // MARK: - Document XML

    private func buildDocumentXML(
        documents: [CompilableDocument],
        title: String,
        author: String,
        settings: CompileSettings,
        progress: ((CompileProgress) -> Void)?
    ) -> String {
        var bodyContent = ""

        // Title page
        if settings.includeTitlePage {
            bodyContent += buildTitlePageXML(title: title, author: author)
            if settings.includeTableOfContents || !documents.isEmpty {
                bodyContent += pageBreakXML()
            }
        }

        // Table of contents
        if settings.includeTableOfContents {
            bodyContent += buildTableOfContentsXML(documents: documents)
            if !documents.isEmpty {
                bodyContent += pageBreakXML()
            }
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
                let headingStyle = doc.depth == 0 ? "Heading1" : "Heading2"
                bodyContent += paragraphXML(text: doc.title, style: headingStyle)
            }

            // Content paragraphs
            let paragraphs = doc.content.components(separatedBy: "\n\n")
            for paragraph in paragraphs {
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    bodyContent += paragraphXML(text: trimmed, style: "Normal")
                }
            }

            // Separator between documents
            if index < documents.count - 1 {
                bodyContent += buildSeparatorXML(settings.documentSeparator)
            }
        }

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
            <w:body>
                \(bodyContent)
                <w:sectPr>
                    <w:pgSz w:w="\(Int(settings.pageSize.dimensions.width * 20))" w:h="\(Int(settings.pageSize.dimensions.height * 20))"/>
                    <w:pgMar w:top="\(Int(settings.margins.top * 20))"
                             w:right="\(Int(settings.margins.trailing * 20))"
                             w:bottom="\(Int(settings.margins.bottom * 20))"
                             w:left="\(Int(settings.margins.leading * 20))"/>
                    \(settings.includePageNumbers ? "<w:pgNumType w:start=\"1\"/><w:footerReference w:type=\"default\" r:id=\"rId2\"/>" : "")
                </w:sectPr>
            </w:body>
        </w:document>
        """
    }

    private func buildTitlePageXML(title: String, author: String) -> String {
        var xml = ""

        // Add spacing before title
        for _ in 0..<6 {
            xml += paragraphXML(text: "", style: "Normal")
        }

        xml += paragraphXML(text: title, style: "Title", centered: true)

        if !author.isEmpty {
            xml += paragraphXML(text: "", style: "Normal")
            xml += paragraphXML(text: "by \(author)", style: "Subtitle", centered: true)
        }

        return xml
    }

    private func buildTableOfContentsXML(documents: [CompilableDocument]) -> String {
        var xml = paragraphXML(text: "Table of Contents", style: "Heading1")

        for doc in documents {
            let indent = String(repeating: "    ", count: doc.depth)
            xml += paragraphXML(text: "\(indent)\(doc.title)", style: "TOC\(min(doc.depth + 1, 3))")
        }

        return xml
    }

    private func buildSeparatorXML(_ separator: DocumentSeparator) -> String {
        switch separator {
        case .none:
            return ""
        case .blankLine:
            return paragraphXML(text: "", style: "Normal")
        case .threeAsterisks:
            return paragraphXML(text: "* * *", style: "Normal", centered: true)
        case .pageBreak, .chapterHeading:
            return pageBreakXML()
        }
    }

    private func paragraphXML(text: String, style: String, centered: Bool = false) -> String {
        let escapedText = escapeXML(text)
        let alignment = centered ? "<w:jc w:val=\"center\"/>" : ""

        return """
        <w:p>
            <w:pPr>
                <w:pStyle w:val="\(style)"/>
                \(alignment)
            </w:pPr>
            <w:r>
                <w:t xml:space="preserve">\(escapedText)</w:t>
            </w:r>
        </w:p>
        """
    }

    private func pageBreakXML() -> String {
        return """
        <w:p>
            <w:r>
                <w:br w:type="page"/>
            </w:r>
        </w:p>
        """
    }

    // MARK: - Supporting XML Files

    private func buildContentTypesXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
            <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
            <Default Extension="xml" ContentType="application/xml"/>
            <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
            <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
            <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
            <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
        </Types>
        """
    }

    private func buildRelsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
            <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
            <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
        </Relationships>
        """
    }

    private func buildDocumentRelsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        </Relationships>
        """
    }

    private func buildStylesXML(settings: CompileSettings) -> String {
        let fontName = settings.fontStyle.fontName
        let fontSize = Int(settings.fontSize * 2) // Half-points
        let lineSpacing = Int(settings.lineSpacing * 240) // Twips (1/20 of a point)

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:docDefaults>
                <w:rPrDefault>
                    <w:rPr>
                        <w:rFonts w:ascii="\(fontName)" w:hAnsi="\(fontName)"/>
                        <w:sz w:val="\(fontSize)"/>
                    </w:rPr>
                </w:rPrDefault>
                <w:pPrDefault>
                    <w:pPr>
                        <w:spacing w:line="\(lineSpacing)" w:lineRule="auto"/>
                    </w:pPr>
                </w:pPrDefault>
            </w:docDefaults>
            <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
                <w:name w:val="Normal"/>
                <w:pPr>
                    <w:spacing w:after="200"/>
                </w:pPr>
            </w:style>
            <w:style w:type="paragraph" w:styleId="Title">
                <w:name w:val="Title"/>
                <w:basedOn w:val="Normal"/>
                <w:pPr>
                    <w:spacing w:after="300"/>
                    <w:jc w:val="center"/>
                </w:pPr>
                <w:rPr>
                    <w:b/>
                    <w:sz w:val="72"/>
                </w:rPr>
            </w:style>
            <w:style w:type="paragraph" w:styleId="Subtitle">
                <w:name w:val="Subtitle"/>
                <w:basedOn w:val="Normal"/>
                <w:pPr>
                    <w:jc w:val="center"/>
                </w:pPr>
                <w:rPr>
                    <w:i/>
                    <w:sz w:val="36"/>
                    <w:color w:val="666666"/>
                </w:rPr>
            </w:style>
            <w:style w:type="paragraph" w:styleId="Heading1">
                <w:name w:val="Heading 1"/>
                <w:basedOn w:val="Normal"/>
                <w:pPr>
                    <w:spacing w:before="480" w:after="240"/>
                </w:pPr>
                <w:rPr>
                    <w:b/>
                    <w:sz w:val="\(fontSize + 12)"/>
                </w:rPr>
            </w:style>
            <w:style w:type="paragraph" w:styleId="Heading2">
                <w:name w:val="Heading 2"/>
                <w:basedOn w:val="Normal"/>
                <w:pPr>
                    <w:spacing w:before="360" w:after="200"/>
                </w:pPr>
                <w:rPr>
                    <w:b/>
                    <w:sz w:val="\(fontSize + 8)"/>
                </w:rPr>
            </w:style>
            <w:style w:type="paragraph" w:styleId="TOC1">
                <w:name w:val="TOC 1"/>
                <w:basedOn w:val="Normal"/>
            </w:style>
            <w:style w:type="paragraph" w:styleId="TOC2">
                <w:name w:val="TOC 2"/>
                <w:basedOn w:val="Normal"/>
                <w:pPr>
                    <w:ind w:left="240"/>
                </w:pPr>
            </w:style>
            <w:style w:type="paragraph" w:styleId="TOC3">
                <w:name w:val="TOC 3"/>
                <w:basedOn w:val="Normal"/>
                <w:pPr>
                    <w:ind w:left="480"/>
                </w:pPr>
            </w:style>
        </w:styles>
        """
    }

    private func buildCorePropertiesXML(title: String, author: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: Date())

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                          xmlns:dc="http://purl.org/dc/elements/1.1/"
                          xmlns:dcterms="http://purl.org/dc/terms/"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <dc:title>\(escapeXML(title))</dc:title>
            <dc:creator>\(escapeXML(author))</dc:creator>
            <dcterms:created xsi:type="dcterms:W3CDTF">\(dateString)</dcterms:created>
            <dcterms:modified xsi:type="dcterms:W3CDTF">\(dateString)</dcterms:modified>
        </cp:coreProperties>
        """
    }

    private func buildAppPropertiesXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
            <Application>Manuscript</Application>
        </Properties>
        """
    }

    // MARK: - ZIP Creation

    private func createDocxZip(
        contentTypes: String,
        rels: String,
        documentRels: String,
        document: String,
        styles: String,
        coreProps: String,
        appProps: String
    ) throws -> Data {
        let zipBuilder = ZipArchiveBuilder()

        try zipBuilder.addFile(path: "[Content_Types].xml", content: contentTypes)
        try zipBuilder.addFile(path: "_rels/.rels", content: rels)
        try zipBuilder.addFile(path: "word/_rels/document.xml.rels", content: documentRels)
        try zipBuilder.addFile(path: "word/document.xml", content: document)
        try zipBuilder.addFile(path: "word/styles.xml", content: styles)
        try zipBuilder.addFile(path: "docProps/core.xml", content: coreProps)
        try zipBuilder.addFile(path: "docProps/app.xml", content: appProps)

        return try zipBuilder.finalize()
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
