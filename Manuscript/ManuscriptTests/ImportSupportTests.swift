import Foundation
import Testing
@testable import Manuscript

struct ImportSupportTests {

    @Test func importFileTypeMapsKnownExtensions() {
        #expect(ImportFileType.from(url: URL(fileURLWithPath: "/tmp/test.docx")) == .docx)
        #expect(ImportFileType.from(url: URL(fileURLWithPath: "/tmp/test.doc")) == .doc)
        #expect(ImportFileType.from(url: URL(fileURLWithPath: "/tmp/test.pdf")) == .pdf)
        #expect(ImportFileType.from(url: URL(fileURLWithPath: "/tmp/test.html")) == .html)
        #expect(ImportFileType.from(url: URL(fileURLWithPath: "/tmp/test.htm")) == .html)
        #expect(ImportFileType.from(url: URL(fileURLWithPath: "/tmp/test.md")) == .markdown)
        #expect(ImportFileType.from(url: URL(fileURLWithPath: "/tmp/test.markdown")) == .markdown)
        #expect(ImportFileType.from(url: URL(fileURLWithPath: "/tmp/test.txt")) == .text)
        #expect(ImportFileType.from(url: URL(fileURLWithPath: "/tmp/test.rtf")) == nil)
    }

    @Test func textMarkdownImporterValidatesSupportedFiles() throws {
        let markdownURL = try createTempFile(named: "chapter.md", content: "# Chapter 1\n\nHello")
        defer { try? FileManager.default.removeItem(at: markdownURL.deletingLastPathComponent()) }

        let textURL = try createTempFile(named: "notes.txt", content: "Just plain notes")
        defer { try? FileManager.default.removeItem(at: textURL.deletingLastPathComponent()) }

        let importer = TextMarkdownImporter()
        let markdownValidation = importer.validate(at: markdownURL)
        let textValidation = importer.validate(at: textURL)

        #expect(markdownValidation.isValid)
        #expect(markdownValidation.documentTitle == "chapter")
        #expect(markdownValidation.errors.isEmpty)

        #expect(textValidation.isValid)
        #expect(textValidation.documentTitle == "notes")
        #expect(textValidation.errors.isEmpty)
    }

    @Test func textMarkdownImporterRejectsUnsupportedExtension() throws {
        let unsupportedURL = try createTempFile(named: "file.rtf", content: "{\\rtf1 test}")
        defer { try? FileManager.default.removeItem(at: unsupportedURL.deletingLastPathComponent()) }

        let validation = TextMarkdownImporter().validate(at: unsupportedURL)
        #expect(validation.isValid == false)
        #expect(validation.errors.isEmpty == false)
    }

    @Test func textMarkdownImporterImportsMarkdownAndText() async throws {
        let markdownURL = try createTempFile(named: "scene.md", content: "**Bold** text")
        defer { try? FileManager.default.removeItem(at: markdownURL.deletingLastPathComponent()) }

        let textURL = try createTempFile(named: "scene.txt", content: "Plain text body")
        defer { try? FileManager.default.removeItem(at: textURL.deletingLastPathComponent()) }

        let importer = TextMarkdownImporter()
        let markdownResult = try await importer.importDocument(
            from: markdownURL,
            options: DocumentImportOptions(preserveFormatting: true)
        )
        let textResult = try await importer.importDocument(
            from: textURL,
            options: DocumentImportOptions(preserveFormatting: true)
        )

        #expect(markdownResult.title == "scene")
        #expect(markdownResult.document.content == "**Bold** text")
        #expect(textResult.document.content == "Plain text body")
    }

    @Test func textMarkdownImporterCanFlattenMarkdownWhenFormattingDisabled() async throws {
        let markdownURL = try createTempFile(named: "flatten.md", content: "**Bold** _italic_")
        defer { try? FileManager.default.removeItem(at: markdownURL.deletingLastPathComponent()) }

        let importer = TextMarkdownImporter()
        let result = try await importer.importDocument(
            from: markdownURL,
            options: DocumentImportOptions(preserveFormatting: false)
        )

        #expect(result.document.content.localizedStandardContains("Bold"))
        #expect(result.document.content.localizedStandardContains("italic"))
        #expect(result.document.content.contains("**") == false)
        #expect(result.document.content.contains("_") == false)
    }

    // MARK: - Helpers

    private func createTempFile(named filename: String, content: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(filename)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
