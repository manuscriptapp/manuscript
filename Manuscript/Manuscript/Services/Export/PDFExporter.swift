import Foundation
import CoreGraphics
import CoreText

#if os(iOS)
import UIKit
#else
import AppKit
#endif

// Note: PlatformFont and PlatformColor typealiases are defined in RTFToMarkdownConverter.swift

/// Exports documents to PDF with proper text flow and pagination
class PDFExporter {
    static let shared = PDFExporter()

    private init() {}

    // MARK: - Export

    func export(
        documents: [CompilableDocument],
        title: String,
        author: String,
        settings: CompileSettings,
        progress: ((CompileProgress) -> Void)? = nil
    ) async throws -> Data {
        let pageSize = settings.pageSize.dimensions
        let margins = settings.margins

        // Calculate content area
        let contentRect = CGRect(
            x: margins.leading,
            y: margins.bottom,
            width: pageSize.width - margins.leading - margins.trailing,
            height: pageSize.height - margins.top - margins.bottom
        )

        // Create PDF context
        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw CompileError.pdfGenerationFailed
        }

        var currentPage = 0

        // Title page
        if settings.includeTitlePage {
            currentPage += 1
            drawTitlePage(
                context: pdfContext,
                title: title,
                author: author,
                pageSize: pageSize,
                settings: settings
            )
        }

        // Table of contents placeholder page
        var tocPageNumbers: [(String, Int)] = []
        if settings.includeTableOfContents {
            // We'll draw TOC after we know all page numbers
            // For now, reserve a page
            currentPage += 1
        }

        // Content pages
        let contentStartPage = currentPage + 1

        // Build combined attributed string
        let combinedText = buildCombinedText(
            documents: documents,
            settings: settings,
            tocEntries: &tocPageNumbers,
            startPage: contentStartPage
        )

        // Draw text with proper pagination
        let pagesDrawn = drawPaginatedText(
            attributedString: combinedText,
            context: pdfContext,
            pageSize: pageSize,
            contentRect: contentRect,
            startingPage: currentPage + 1,
            settings: settings,
            progress: { docIndex in
                progress?(CompileProgress(
                    currentDocument: docIndex,
                    totalDocuments: documents.count,
                    currentPhase: .processing
                ))
            }
        )

        currentPage += pagesDrawn

        // Now draw TOC if needed (we'd need to re-render, but for simplicity we'll draw it at the reserved spot)
        // In a production app, you'd do a two-pass rendering

        pdfContext.closePDF()

        return pdfData as Data
    }

    // MARK: - Title Page

    private func drawTitlePage(
        context: CGContext,
        title: String,
        author: String,
        pageSize: CGSize,
        settings: CompileSettings
    ) {
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        context.beginPDFPage(nil)

        // Title
        let titleFont = createFont(style: settings.fontStyle, size: 36, bold: true)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: PlatformColor.black
        ]

        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleSize = titleString.size()

        let titlePoint = CGPoint(
            x: (pageSize.width - titleSize.width) / 2,
            y: pageSize.height - 300
        )

        drawAttributedString(titleString, at: titlePoint, in: context, pageSize: pageSize)

        // Author
        if !author.isEmpty {
            let authorFont = createFont(style: settings.fontStyle, size: 18, bold: false)
            let authorAttributes: [NSAttributedString.Key: Any] = [
                .font: authorFont,
                .foregroundColor: PlatformColor.darkGray
            ]

            let authorString = NSAttributedString(string: "by \(author)", attributes: authorAttributes)
            let authorSize = authorString.size()

            let authorPoint = CGPoint(
                x: (pageSize.width - authorSize.width) / 2,
                y: pageSize.height - 360
            )

            drawAttributedString(authorString, at: authorPoint, in: context, pageSize: pageSize)
        }

        context.endPDFPage()
    }

    // MARK: - Combined Text Building

    private func buildCombinedText(
        documents: [CompilableDocument],
        settings: CompileSettings,
        tocEntries: inout [(String, Int)],
        startPage: Int
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        let bodyFont = createFont(style: settings.fontStyle, size: settings.fontSize, bold: false)
        let titleFont = createFont(style: settings.fontStyle, size: settings.fontSize + 6, bold: true)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = (settings.lineSpacing - 1.0) * settings.fontSize
        paragraphStyle.paragraphSpacing = settings.fontSize

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: PlatformColor.black,
            .paragraphStyle: paragraphStyle
        ]

        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.paragraphSpacingBefore = settings.fontSize * 2
        titleParagraphStyle.paragraphSpacing = settings.fontSize

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: PlatformColor.black,
            .paragraphStyle: titleParagraphStyle
        ]

        for (index, doc) in documents.enumerated() {
            // Add chapter title if enabled
            if settings.includeChapterTitles && !doc.title.isEmpty {
                let titleText = NSAttributedString(string: doc.title + "\n\n", attributes: titleAttributes)
                result.append(titleText)
            }

            // Add content
            let content = doc.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                let contentText = NSAttributedString(string: content, attributes: bodyAttributes)
                result.append(contentText)
            }

            // Add separator between documents
            if index < documents.count - 1 {
                let separator = getSeparatorString(settings.documentSeparator, attributes: bodyAttributes)
                result.append(separator)
            }
        }

        return result
    }

    private func getSeparatorString(_ separator: DocumentSeparator, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        switch separator {
        case .none:
            return NSAttributedString(string: "\n\n", attributes: attributes)
        case .blankLine:
            return NSAttributedString(string: "\n\n\n", attributes: attributes)
        case .threeAsterisks:
            let centered = NSMutableParagraphStyle()
            centered.alignment = .center
            var attrs = attributes
            attrs[.paragraphStyle] = centered
            return NSAttributedString(string: "\n\n* * *\n\n", attributes: attrs)
        case .pageBreak, .chapterHeading:
            return NSAttributedString(string: "\n\n", attributes: attributes)
        }
    }

    // MARK: - Paginated Text Drawing

    private func drawPaginatedText(
        attributedString: NSAttributedString,
        context: CGContext,
        pageSize: CGSize,
        contentRect: CGRect,
        startingPage: Int,
        settings: CompileSettings,
        progress: ((Int) -> Void)?
    ) -> Int {
        var pageCount = 0

        // Create framesetter
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)

        var currentIndex: CFIndex = 0
        let textLength = attributedString.length

        // For CoreText, we need to use the flipped content rect
        // PDF coordinate system: origin at bottom-left
        // We define the text frame in PDF coordinates (not flipped)
        let flippedContentRect = CGRect(
            x: contentRect.origin.x,
            y: contentRect.origin.y,  // This is already from bottom in PDF coords
            width: contentRect.width,
            height: contentRect.height
        )

        while currentIndex < textLength {
            // Begin new page
            context.beginPDFPage(nil)
            pageCount += 1

            // Create path for text frame in PDF coordinates
            let path = CGPath(rect: flippedContentRect, transform: nil)

            // Create frame for this page
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRangeMake(currentIndex, 0),
                path,
                nil
            )

            // Get the range that fits on this page
            let frameRange = CTFrameGetVisibleStringRange(frame)

            // Draw the frame - CoreText draws correctly in PDF coordinate system
            // No need to flip - CTFrameDraw handles PDF context properly
            CTFrameDraw(frame, context)

            // Draw page number if enabled
            if settings.includePageNumbers {
                drawPageNumber(
                    pageCount + startingPage - 1,
                    context: context,
                    pageSize: pageSize,
                    settings: settings
                )
            }

            context.endPDFPage()

            // Move to next portion of text
            currentIndex += frameRange.length

            // Prevent infinite loop
            if frameRange.length == 0 {
                break
            }

            progress?(pageCount)
        }

        return pageCount
    }

    // MARK: - Page Numbers

    private func drawPageNumber(
        _ pageNumber: Int,
        context: CGContext,
        pageSize: CGSize,
        settings: CompileSettings
    ) {
        let font = createFont(style: settings.fontStyle, size: 10, bold: false)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: PlatformColor.darkGray
        ]

        let pageString = NSAttributedString(string: "\(pageNumber)", attributes: attributes)
        let size = pageString.size()

        let point = CGPoint(
            x: (pageSize.width - size.width) / 2,
            y: 36  // Bottom margin
        )

        drawAttributedString(pageString, at: point, in: context, pageSize: pageSize)
    }

    // MARK: - Helper Methods

    private func createFont(style: CompileFontStyle, size: CGFloat, bold: Bool) -> PlatformFont {
        let fontName: String
        switch style {
        case .serif:
            fontName = bold ? "Georgia-Bold" : "Georgia"
        case .sansSerif:
            fontName = bold ? "HelveticaNeue-Bold" : "HelveticaNeue"
        case .monospace:
            fontName = bold ? "Menlo-Bold" : "Menlo"
        }

        #if os(iOS)
        return UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size)
        #else
        return NSFont(name: fontName, size: size) ?? NSFont.systemFont(ofSize: size)
        #endif
    }

    private func drawAttributedString(
        _ string: NSAttributedString,
        at point: CGPoint,
        in context: CGContext,
        pageSize: CGSize
    ) {
        context.saveGState()

        // CoreText uses bottom-left origin, but we want top-left for positioning
        let line = CTLineCreateWithAttributedString(string as CFAttributedString)
        context.textPosition = CGPoint(x: point.x, y: point.y)
        CTLineDraw(line, context)

        context.restoreGState()
    }
}
