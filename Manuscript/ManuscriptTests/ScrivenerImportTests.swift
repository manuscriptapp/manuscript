//
//  ScrivenerImportTests.swift
//  ManuscriptTests
//
//  Tests for Scrivener project import functionality
//

import Testing
import Foundation
@testable import Manuscript

struct ScrivenerImportTests {

    // MARK: - XML Parser Tests

    @Test func parserHandlesSimpleProject() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ScrivenerProject Version="2.0">
            <ProjectTitle>Test Project</ProjectTitle>
            <Binder>
                <BinderItem ID="1" Type="DraftFolder" Created="2025-01-01">
                    <Title>Draft</Title>
                    <Children>
                        <BinderItem ID="2" Type="Text" Created="2025-01-02">
                            <Title>Chapter One</Title>
                            <Synopsis>The beginning of the story.</Synopsis>
                        </BinderItem>
                    </Children>
                </BinderItem>
            </Binder>
        </ScrivenerProject>
        """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_project.scrivx")
        try xml.write(to: tempURL, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let parser = ScrivenerXMLParser()
        let project = try parser.parse(projectURL: tempURL)

        #expect(project.title == "Test Project")
        #expect(project.binderItems.count == 1)
        #expect(project.binderItems[0].type == .draftFolder)
        #expect(project.binderItems[0].children.count == 1)
        #expect(project.binderItems[0].children[0].title == "Chapter One")
        #expect(project.binderItems[0].children[0].synopsis == "The beginning of the story.")
    }

    @Test func parserHandlesNestedFolders() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ScrivenerProject Version="2.0">
            <ProjectTitle>Nested Project</ProjectTitle>
            <Binder>
                <BinderItem ID="1" Type="DraftFolder">
                    <Title>Draft</Title>
                    <Children>
                        <BinderItem ID="2" Type="Folder">
                            <Title>Part One</Title>
                            <Children>
                                <BinderItem ID="3" Type="Folder">
                                    <Title>Chapter One</Title>
                                    <Children>
                                        <BinderItem ID="4" Type="Text">
                                            <Title>Scene 1</Title>
                                        </BinderItem>
                                    </Children>
                                </BinderItem>
                            </Children>
                        </BinderItem>
                    </Children>
                </BinderItem>
            </Binder>
        </ScrivenerProject>
        """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("nested_project.scrivx")
        try xml.write(to: tempURL, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let parser = ScrivenerXMLParser()
        let project = try parser.parse(projectURL: tempURL)

        #expect(project.title == "Nested Project")

        let draft = project.binderItems[0]
        let partOne = draft.children[0]
        let chapterOne = partOne.children[0]
        let scene1 = chapterOne.children[0]

        #expect(draft.title == "Draft")
        #expect(partOne.title == "Part One")
        #expect(chapterOne.title == "Chapter One")
        #expect(scene1.title == "Scene 1")
        #expect(scene1.type == .text)
    }

    @Test func parserHandlesLabelsAndStatuses() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ScrivenerProject Version="2.0">
            <ProjectTitle>Labels Test</ProjectTitle>
            <Binder>
                <BinderItem ID="1" Type="DraftFolder">
                    <Title>Draft</Title>
                    <Children>
                        <BinderItem ID="2" Type="Text">
                            <Title>Document</Title>
                            <MetaData>
                                <LabelID>1</LabelID>
                                <StatusID>2</StatusID>
                            </MetaData>
                        </BinderItem>
                    </Children>
                </BinderItem>
            </Binder>
            <LabelSettings>
                <Labels>
                    <Label ID="0" Color="0.5 0.5 0.5">No Label</Label>
                    <Label ID="1" Color="1.0 0.0 0.0">Red</Label>
                </Labels>
            </LabelSettings>
            <StatusSettings>
                <StatusItems>
                    <Status ID="0">No Status</Status>
                    <Status ID="1">To Do</Status>
                    <Status ID="2">First Draft</Status>
                </StatusItems>
            </StatusSettings>
        </ScrivenerProject>
        """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("labels_project.scrivx")
        try xml.write(to: tempURL, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let parser = ScrivenerXMLParser()
        let project = try parser.parse(projectURL: tempURL)

        #expect(project.labels.count == 2)
        #expect(project.labels[1].name == "Red")
        #expect(project.labels[1].id == 1)

        #expect(project.statuses.count == 3)
        #expect(project.statuses[2].name == "First Draft")

        let document = project.binderItems[0].children[0]
        #expect(document.labelID == 1)
        #expect(document.statusID == 2)
    }

    @Test func parserHandlesProjectTargets() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ScrivenerProject Version="2.0">
            <ProjectTitle>Targets Test</ProjectTitle>
            <Binder></Binder>
            <ProjectTargets>
                <DraftTarget>80000</DraftTarget>
                <SessionTarget>1000</SessionTarget>
            </ProjectTargets>
        </ScrivenerProject>
        """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("targets_project.scrivx")
        try xml.write(to: tempURL, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let parser = ScrivenerXMLParser()
        let project = try parser.parse(projectURL: tempURL)

        #expect(project.targets?.draftWordCount == 80000)
        #expect(project.targets?.sessionWordCount == 1000)
    }

    // MARK: - RTF Converter Tests

    @Test func rtfConverterHandlesPlainText() async throws {
        let rtf = "{\\rtf1\\ansi Hello World}"
        let data = rtf.data(using: .utf8)!

        let converter = RTFToMarkdownConverter()
        let result = try converter.convert(rtfData: data)

        #expect(result.contains("Hello World"))
    }

    // MARK: - Model Tests

    @Test func scrivenerItemTypeInitialization() {
        #expect(ScrivenerItemType(rawValue: "DraftFolder") == .draftFolder)
        #expect(ScrivenerItemType(rawValue: "ResearchFolder") == .researchFolder)
        #expect(ScrivenerItemType(rawValue: "TrashFolder") == .trashFolder)
        #expect(ScrivenerItemType(rawValue: "Folder") == .folder)
        #expect(ScrivenerItemType(rawValue: "Text") == .text)
        #expect(ScrivenerItemType(rawValue: "PDF") == .pdf)
        #expect(ScrivenerItemType(rawValue: "Image") == .image)
        #expect(ScrivenerItemType(rawValue: "Unknown") == .other)
    }

    @Test func importOptionsDefaults() {
        let options = ScrivenerImportOptions.default

        #expect(options.importSnapshots == true)
        #expect(options.importTrash == false)
        #expect(options.importResearch == true)
        #expect(options.preserveScrivenerIDs == false)
    }

    @Test func importOptionsCustomization() {
        let options = ScrivenerImportOptions(
            importSnapshots: false,
            importTrash: true,
            importResearch: false,
            preserveScrivenerIDs: true
        )

        #expect(options.importSnapshots == false)
        #expect(options.importTrash == true)
        #expect(options.importResearch == false)
        #expect(options.preserveScrivenerIDs == true)
    }

    // MARK: - Validation Tests

    @Test func validatorDetectsInvalidBundle() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let importer = ScrivenerImporter()
        let result = importer.validateProject(at: tempDir)

        #expect(result.isValid == false)
        #expect(result.errors.count > 0)
    }

    @Test func validatorAcceptsValidBundle() async throws {
        let bundleURL = FileManager.default.temporaryDirectory.appendingPathComponent("Valid.scriv")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ScrivenerProject Version="2.0">
            <ProjectTitle>Valid Project</ProjectTitle>
            <Binder>
                <BinderItem ID="1" Type="DraftFolder">
                    <Title>Draft</Title>
                </BinderItem>
            </Binder>
        </ScrivenerProject>
        """

        let scrivxURL = bundleURL.appendingPathComponent("project.scrivx")
        try xml.write(to: scrivxURL, atomically: true, encoding: .utf8)

        let docsURL = bundleURL.appendingPathComponent("Files/Docs")
        try FileManager.default.createDirectory(at: docsURL, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: bundleURL)
        }

        let importer = ScrivenerImporter()
        let result = importer.validateProject(at: bundleURL)

        #expect(result.isValid == true)
        #expect(result.projectTitle == "Valid Project")
        #expect(result.itemCount == 1)
        #expect(result.version == .v2)
    }

    @Test func validatorDetectsV3Format() async throws {
        let bundleURL = FileManager.default.temporaryDirectory.appendingPathComponent("V3Project.scriv")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ScrivenerProject Version="2.0">
            <ProjectTitle>V3 Project</ProjectTitle>
            <Binder></Binder>
        </ScrivenerProject>
        """

        let scrivxURL = bundleURL.appendingPathComponent("project.scrivx")
        try xml.write(to: scrivxURL, atomically: true, encoding: .utf8)

        let dataURL = bundleURL.appendingPathComponent("Files/Data")
        try FileManager.default.createDirectory(at: dataURL, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: bundleURL)
        }

        let importer = ScrivenerImporter()
        let result = importer.validateProject(at: bundleURL)

        #expect(result.version == .v3)
    }

    // MARK: - Import Result Tests

    @Test func importResultSummary() {
        let result = ImportResult(
            document: ManuscriptDocument(),
            warnings: [],
            skippedItems: 0,
            importedDocuments: 5,
            importedFolders: 2
        )

        #expect(result.summary.contains("5 documents"))
        #expect(result.summary.contains("2 folders"))
        #expect(result.hasWarnings == false)
    }

    @Test func importResultWithWarnings() {
        let result = ImportResult(
            document: ManuscriptDocument(),
            warnings: [
                ImportWarning(message: "Test warning", itemTitle: "Item1", severity: .warning)
            ],
            skippedItems: 1,
            importedDocuments: 3,
            importedFolders: 1
        )

        #expect(result.hasWarnings == true)
        #expect(result.summary.contains("skipped"))
    }

    // MARK: - Error Tests

    @Test func importErrorDescriptions() {
        let notABundle = ImportError.notABundle
        #expect(notABundle.errorDescription?.isEmpty == false)

        let missingProject = ImportError.missingProjectFile
        #expect(missingProject.errorDescription?.isEmpty == false)

        let xmlError = ImportError.xmlParsingFailed("test")
        #expect(xmlError.errorDescription?.contains("test") == true)

        let rtfError = ImportError.rtfConversionFailed("conversion issue")
        #expect(rtfError.errorDescription?.contains("conversion issue") == true)
    }

    // MARK: - New Format Tests

    @Test func manuscriptDocumentSupportsLabels() {
        var doc = ManuscriptDocument()
        doc.labels = [
            ManuscriptLabel(id: "test-1", name: "Test Label", color: "#FF0000")
        ]

        #expect(doc.labels.count == 1)
        #expect(doc.labels[0].name == "Test Label")
        #expect(doc.labels[0].color == "#FF0000")
    }

    @Test func manuscriptDocumentSupportsStatuses() {
        var doc = ManuscriptDocument()
        doc.statuses = [
            ManuscriptStatus(id: "status-1", name: "Draft")
        ]

        #expect(doc.statuses.count == 1)
        #expect(doc.statuses[0].name == "Draft")
    }

    @Test func manuscriptDocumentSupportsTargets() {
        var doc = ManuscriptDocument()
        doc.targets = ManuscriptTargets(
            draftWordCount: 50000,
            sessionWordCount: 1000
        )

        #expect(doc.targets.draftWordCount == 50000)
        #expect(doc.targets.sessionWordCount == 1000)
    }

    @Test func manuscriptFolderSupportsTypes() {
        let draftFolder = ManuscriptFolder(title: "Draft", folderType: .draft)
        let notesFolder = ManuscriptFolder(title: "Notes", folderType: .notes)
        let researchFolder = ManuscriptFolder(title: "Research", folderType: .research)

        #expect(draftFolder.folderType == .draft)
        #expect(notesFolder.folderType == .notes)
        #expect(researchFolder.folderType == .research)
    }

    @Test func documentSupportsScrivenerMetadata() {
        let doc = ManuscriptDocument.Document(
            title: "Test",
            labelId: "label-1",
            statusId: "status-1",
            keywords: ["test", "demo"],
            includeInCompile: false
        )

        #expect(doc.labelId == "label-1")
        #expect(doc.statusId == "status-1")
        #expect(doc.keywords.count == 2)
        #expect(doc.includeInCompile == false)
    }

    // MARK: - Integration Test

    @Test func fullImportWorkflow() async throws {
        let bundleURL = FileManager.default.temporaryDirectory.appendingPathComponent("FullTest.scriv")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ScrivenerProject Version="2.0">
            <ProjectTitle>Full Test Project</ProjectTitle>
            <Binder>
                <BinderItem ID="1" Type="DraftFolder">
                    <Title>Draft</Title>
                    <Children>
                        <BinderItem ID="2" Type="Text">
                            <Title>Chapter One</Title>
                            <Synopsis>The story begins.</Synopsis>
                        </BinderItem>
                        <BinderItem ID="3" Type="Text">
                            <Title>Chapter Two</Title>
                        </BinderItem>
                    </Children>
                </BinderItem>
                <BinderItem ID="10" Type="ResearchFolder">
                    <Title>Research</Title>
                    <Children>
                        <BinderItem ID="11" Type="Text">
                            <Title>Notes</Title>
                        </BinderItem>
                    </Children>
                </BinderItem>
            </Binder>
            <LabelSettings>
                <Labels>
                    <Label ID="1" Color="1.0 0.0 0.0">Important</Label>
                </Labels>
            </LabelSettings>
            <StatusSettings>
                <StatusItems>
                    <Status ID="1">Draft</Status>
                </StatusItems>
            </StatusSettings>
        </ScrivenerProject>
        """

        let scrivxURL = bundleURL.appendingPathComponent("project.scrivx")
        try xml.write(to: scrivxURL, atomically: true, encoding: .utf8)

        let docsURL = bundleURL.appendingPathComponent("Files/Docs")
        try FileManager.default.createDirectory(at: docsURL, withIntermediateDirectories: true)

        let rtf1 = "{\\rtf1\\ansi This is chapter one content.}"
        try rtf1.write(to: docsURL.appendingPathComponent("2.rtf"), atomically: true, encoding: .utf8)

        let rtf2 = "{\\rtf1\\ansi This is chapter two content.}"
        try rtf2.write(to: docsURL.appendingPathComponent("3.rtf"), atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: bundleURL)
        }

        let importer = ScrivenerImporter()
        let result = try await importer.importProject(from: bundleURL)

        #expect(result.document.title == "Full Test Project")
        #expect(result.document.rootFolder.title == "Draft")
        #expect(result.document.rootFolder.folderType == .draft)
        #expect(result.document.rootFolder.documents.count == 2)
        #expect(result.document.rootFolder.documents[0].title == "Chapter One")
        #expect(result.document.rootFolder.documents[0].outline == "The story begins.")
        #expect(result.document.rootFolder.documents[0].content.contains("chapter one content"))

        // Check that labels were imported
        #expect(result.document.labels.count >= 1)
        #expect(result.document.labels.first?.name == "Important")

        // Check that statuses were imported
        #expect(result.document.statuses.count >= 1)
        #expect(result.document.statuses.first?.name == "Draft")

        // Check that research folder was imported
        #expect(result.document.researchFolder != nil)
        #expect(result.document.researchFolder?.folderType == .research)

        // Check import statistics
        #expect(result.importedDocuments >= 2)
        #expect(result.importedFolders >= 1)
    }
}
