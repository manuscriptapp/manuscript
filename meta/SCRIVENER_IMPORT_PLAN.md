# Scrivener Import Plan for Manuscript

Version: 1.0
Date: 2026-01-11

## Overview

This document outlines the implementation plan for importing Scrivener projects (`.scriv` bundles) into the Manuscript application. The goal is to provide seamless migration for users switching from Scrivener to Manuscript while preserving their content, structure, and metadata.

---

## 1. Scrivener File Format Analysis

### 1.1 Bundle Structure

Scrivener projects are macOS/iOS bundles (directories) with the `.scriv` extension:

```
MyNovel.scriv/
├── project.scrivx              # Main XML file - project structure & metadata
├── Files/
│   ├── binder.autosave         # Autosave state
│   ├── binder.backup           # Backup of binder state
│   ├── Docs/                   # Document content files
│   │   ├── 1.rtf               # RTF content (or .txt for plain text mode)
│   │   ├── 2.rtf
│   │   ├── 3_notes.rtf         # Document notes
│   │   ├── 3_synopsis.txt      # Document synopsis
│   │   └── ...
│   ├── Data/                   # Scrivener 3 format
│   │   ├── 12345678-ABCD-.../  # UUID-based folders
│   │   │   ├── content.rtf     # Document content
│   │   │   ├── notes.rtf       # Document notes
│   │   │   └── synopsis.txt    # Synopsis
│   │   └── ...
│   └── search.indexes          # Search index cache
├── Settings/
│   ├── compile.xml             # Compile settings
│   ├── favorites.xml           # Favorite documents
│   ├── recents.xml             # Recent documents
│   └── ui.xml                  # UI state
├── Snapshots/                  # Document snapshots
│   ├── 1/                      # By document ID
│   │   ├── 2025-01-01.rtf
│   │   └── snapshot.xml
│   └── ...
└── QuickLook/
    └── Preview.html            # Quick Look preview
```

### 1.2 Project.scrivx Structure (XML)

The `project.scrivx` file is the heart of a Scrivener project:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ScrivenerProject Version="2.0">
  <ProjectTitle>My Novel</ProjectTitle>
  <ProjectBookmarks/>

  <Binder>
    <BinderItem ID="1" Type="DraftFolder" Created="2025-01-01" Modified="2025-01-10">
      <Title>Draft</Title>
      <MetaData>
        <IncludeInCompile>Yes</IncludeInCompile>
      </MetaData>
      <Children>
        <BinderItem ID="2" Type="Text" Created="2025-01-02" Modified="2025-01-09">
          <Title>Chapter One</Title>
          <MetaData>
            <LabelID>1</LabelID>
            <StatusID>2</StatusID>
            <IncludeInCompile>Yes</IncludeInCompile>
            <Target Type="Words">2000</Target>
          </MetaData>
          <Synopsis>The story begins here.</Synopsis>
          <TextSettings>
            <TextSelection>0,0</TextSelection>
          </TextSettings>
        </BinderItem>
        <BinderItem ID="3" Type="Folder" Created="2025-01-03" Modified="2025-01-08">
          <Title>Chapter Two</Title>
          <Children>
            <BinderItem ID="4" Type="Text">...</BinderItem>
          </Children>
        </BinderItem>
      </Children>
    </BinderItem>

    <BinderItem ID="10" Type="ResearchFolder">
      <Title>Research</Title>
      <Children>...</Children>
    </BinderItem>

    <BinderItem ID="20" Type="TrashFolder">
      <Title>Trash</Title>
      <Children>...</Children>
    </BinderItem>
  </Binder>

  <LabelSettings>
    <Labels>
      <Label ID="0" Color="0.0 0.0 0.0">No Label</Label>
      <Label ID="1" Color="1.0 0.0 0.0">Red</Label>
      <Label ID="2" Color="0.0 1.0 0.0">Green</Label>
      <Label ID="3" Color="0.0 0.0 1.0">Blue</Label>
    </Labels>
  </LabelSettings>

  <StatusSettings>
    <StatusItems>
      <Status ID="0">No Status</Status>
      <Status ID="1">To Do</Status>
      <Status ID="2">First Draft</Status>
      <Status ID="3">Revised</Status>
      <Status ID="4">Final</Status>
    </StatusItems>
  </StatusSettings>

  <CustomMetaDataSettings>
    <CustomMetaData>
      <Field ID="1" Type="Text" Title="POV Character"/>
      <Field ID="2" Type="Checkbox" Title="Needs Review"/>
    </CustomMetaData>
  </CustomMetaDataSettings>

  <ProjectSettings>
    <WritingDirection>LeftToRight</WritingDirection>
  </ProjectSettings>

  <ProjectTargets>
    <DraftTarget Type="Words">80000</DraftTarget>
    <SessionTarget Type="Words">1000</SessionTarget>
  </ProjectTargets>
</ScrivenerProject>
```

### 1.3 Binder Item Types

| Scrivener Type | Description | Manuscript Mapping |
|----------------|-------------|-------------------|
| `DraftFolder` | Main manuscript folder | `contents/draft/` |
| `ResearchFolder` | Research materials | `contents/research/` |
| `TrashFolder` | Deleted items | `trash/` |
| `Folder` | User folder | Subfolder in appropriate section |
| `Text` | Text document | `.md` file |
| `PDF` | PDF document | `assets/` + reference |
| `Image` | Image file | `assets/` + reference |
| `WebPage` | Archived webpage | `assets/` + reference |

### 1.4 Content File Formats

**Scrivener 2.x:**
- Content: `Files/Docs/{ID}.rtf` or `{ID}.txt`
- Notes: `Files/Docs/{ID}_notes.rtf`
- Synopsis: `Files/Docs/{ID}_synopsis.txt`

**Scrivener 3.x:**
- Content: `Files/Data/{UUID}/content.rtf`
- Notes: `Files/Data/{UUID}/notes.rtf`
- Synopsis: `Files/Data/{UUID}/synopsis.txt`

---

## 2. Mapping Strategy

### 2.1 Project Metadata Mapping

| Scrivener | Manuscript (`project.json`) |
|-----------|----------------------------|
| `<ProjectTitle>` | `title` |
| `<ProjectTargets>` → `DraftTarget` | `targets.draft.wordCount` |
| `<ProjectTargets>` → `SessionTarget` | `targets.session.wordCount` |
| `<LabelSettings>` | `labels[]` |
| `<StatusSettings>` | `statuses[]` |

### 2.2 Binder to Contents Mapping

```
Scrivener Binder                    Manuscript Contents
================                    ===================
DraftFolder/                   →    contents/draft/
├── Chapter One (Text)         →    ├── 01-chapter-one.md
├── Chapter Two (Folder)/      →    ├── 02-chapter-two/
│   ├── Scene 1 (Text)         →    │   ├── 01-scene-1.md
│   └── Scene 2 (Text)         →    │   └── 02-scene-2.md
└── Chapter Three (Text)       →    └── 03-chapter-three.md

ResearchFolder/                →    contents/research/
├── Notes (Text)               →    ├── 01-notes.md
└── Reference.pdf (PDF)        →    └── [copy to assets/]

TrashFolder/                   →    trash/
└── Deleted Scene (Text)       →    └── 01-deleted-scene.md
```

### 2.3 Document Metadata Mapping

| Scrivener (`BinderItem`) | Manuscript (`folder.json` item) |
|--------------------------|--------------------------------|
| `ID` | Generated UUID |
| `Title` | `title` |
| `Created` | `created` |
| `Modified` | `modified` |
| `LabelID` → Label name | `label` (label ID reference) |
| `StatusID` → Status name | `status` (status ID reference) |
| `Synopsis` | `synopsis` |
| `IncludeInCompile` | `includeInCompile` |
| `Target.Words` | `target.wordCount` (future feature) |

### 2.4 Content Conversion

**RTF to Markdown conversion:**

| RTF Feature | Markdown Output |
|-------------|-----------------|
| `\b bold \b0` | `**bold**` |
| `\i italic \i0` | `*italic*` |
| `\ul underline \ul0` | `_underline_` (or HTML `<u>`) |
| `\strike strikethrough` | `~~strikethrough~~` |
| `\bullet` list | `- item` |
| `{\field...}` hyperlink | `[text](url)` |
| `\pard\s1` Heading 1 | `# Heading` |
| `\pard\s2` Heading 2 | `## Heading` |
| Line breaks | Preserved |
| Footnotes | `[^1]` + footnote section |
| Comments | `<!-- comment -->` or in `notes` field |
| Inline annotations | Store in document notes |

---

## 3. Implementation Architecture

### 3.1 New Files to Create

```
Manuscript/
├── Services/
│   └── Import/
│       ├── ScrivenerImporter.swift       # Main import orchestrator
│       ├── ScrivenerXMLParser.swift      # XML parsing for .scrivx
│       ├── ScrivenerModels.swift         # Scrivener data structures
│       ├── RTFToMarkdownConverter.swift  # RTF → Markdown conversion
│       └── ImportError.swift             # Error types
│
├── Views/
│   └── Import/
│       ├── ImportView.swift              # Import wizard UI
│       ├── ImportProgressView.swift      # Progress indicator
│       └── ImportOptionsView.swift       # Import configuration
│
└── Extensions/
    └── URL+Scrivener.swift               # URL helpers for .scriv bundles
```

### 3.2 Core Data Structures

```swift
// ScrivenerModels.swift

/// Represents a parsed Scrivener project
struct ScrivenerProject {
    let title: String
    let version: ScrivenerVersion
    let binderItems: [ScrivenerBinderItem]
    let labels: [ScrivenerLabel]
    let statuses: [ScrivenerStatus]
    let targets: ScrivenerTargets?
    let customMetadata: [ScrivenerCustomField]
}

enum ScrivenerVersion {
    case v2  // Scrivener 2.x format
    case v3  // Scrivener 3.x format
}

/// Represents a binder item (folder or document)
struct ScrivenerBinderItem {
    let id: String
    let uuid: String?           // Scrivener 3 UUID
    let type: ScrivenerItemType
    let title: String
    let created: Date?
    let modified: Date?
    let synopsis: String?
    let labelID: Int?
    let statusID: Int?
    let includeInCompile: Bool
    let children: [ScrivenerBinderItem]
    let targetWordCount: Int?
}

enum ScrivenerItemType: String {
    case draftFolder = "DraftFolder"
    case researchFolder = "ResearchFolder"
    case trashFolder = "TrashFolder"
    case folder = "Folder"
    case text = "Text"
    case pdf = "PDF"
    case image = "Image"
    case webPage = "WebPage"
    case other = "Other"
}

struct ScrivenerLabel {
    let id: Int
    let name: String
    let color: Color       // Parsed from RGB string
}

struct ScrivenerStatus {
    let id: Int
    let name: String
}

struct ScrivenerTargets {
    let draftWordCount: Int?
    let sessionWordCount: Int?
    let deadline: Date?
}
```

### 3.3 Import Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     ScrivenerImporter                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Validate Bundle                                          │
│     └── Check .scriv structure, find project.scrivx          │
│                                                              │
│  2. Parse XML                                                │
│     └── ScrivenerXMLParser.parse(projectURL)                 │
│         ├── Parse <Binder> → [ScrivenerBinderItem]           │
│         ├── Parse <LabelSettings> → [ScrivenerLabel]         │
│         ├── Parse <StatusSettings> → [ScrivenerStatus]       │
│         └── Parse <ProjectTargets> → ScrivenerTargets        │
│                                                              │
│  3. Detect Version                                           │
│     └── Check for Files/Data/ (v3) vs Files/Docs/ (v2)       │
│                                                              │
│  4. Convert Content                                          │
│     └── For each text BinderItem:                            │
│         ├── Load RTF from Files/Docs/{ID}.rtf or             │
│         │   Files/Data/{UUID}/content.rtf                    │
│         ├── RTFToMarkdownConverter.convert(rtfData)          │
│         ├── Load synopsis from {ID}_synopsis.txt             │
│         └── Load notes from {ID}_notes.rtf                   │
│                                                              │
│  5. Build Manuscript Structure                               │
│     ├── Create project.json with metadata                    │
│     ├── Create contents/draft/ from DraftFolder              │
│     ├── Create contents/research/ from ResearchFolder        │
│     ├── Create trash/ from TrashFolder                       │
│     ├── Copy assets to assets/                               │
│     └── Create folder.json files with item metadata          │
│                                                              │
│  6. Import Snapshots (Optional)                              │
│     └── Convert Snapshots/{ID}/*.rtf to snapshots/           │
│                                                              │
│  7. Finalize                                                 │
│     └── Return ManuscriptDocument or save to disk            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Implementation Details

### 4.1 ScrivenerImporter

```swift
// ScrivenerImporter.swift

import Foundation
import UniformTypeIdentifiers

/// Main entry point for Scrivener project import
class ScrivenerImporter {

    // MARK: - Properties

    private let xmlParser: ScrivenerXMLParser
    private let rtfConverter: RTFToMarkdownConverter

    // MARK: - Initialization

    init() {
        self.xmlParser = ScrivenerXMLParser()
        self.rtfConverter = RTFToMarkdownConverter()
    }

    // MARK: - Public Methods

    /// Import a Scrivener project from URL
    /// - Parameters:
    ///   - url: URL to the .scriv bundle
    ///   - options: Import configuration options
    ///   - progress: Progress callback (0.0 to 1.0)
    /// - Returns: Imported ManuscriptDocument
    func importProject(
        from url: URL,
        options: ImportOptions = .default,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> ManuscriptDocument {

        // 1. Validate bundle structure
        progress?(0.05, "Validating Scrivener project...")
        try validateBundle(at: url)

        // 2. Parse project.scrivx
        progress?(0.10, "Reading project structure...")
        let projectURL = url.appendingPathComponent("project.scrivx")
        let scrivProject = try xmlParser.parse(projectURL: projectURL)

        // 3. Detect version and content location
        let version = detectVersion(at: url)
        let contentPath = version == .v3 ? "Files/Data" : "Files/Docs"

        // 4. Create Manuscript document
        let manuscript = ManuscriptDocument()
        manuscript.title = scrivProject.title
        manuscript.creationDate = Date()

        // 5. Map labels and statuses
        // (Store for reference during binder conversion)
        let labelMap = Dictionary(uniqueKeysWithValues:
            scrivProject.labels.map { ($0.id, $0) }
        )
        let statusMap = Dictionary(uniqueKeysWithValues:
            scrivProject.statuses.map { ($0.id, $0) }
        )

        // 6. Convert binder items to folders/documents
        progress?(0.20, "Converting documents...")
        let totalItems = countBinderItems(scrivProject.binderItems)
        var convertedCount = 0

        for binderItem in scrivProject.binderItems {
            let folder = try await convertBinderItem(
                binderItem,
                projectURL: url,
                contentPath: contentPath,
                version: version,
                labelMap: labelMap,
                statusMap: statusMap,
                options: options
            ) { converted in
                convertedCount += converted
                let itemProgress = 0.20 + (Double(convertedCount) / Double(totalItems)) * 0.70
                progress?(itemProgress, "Converting: \(binderItem.title)")
            }

            // Map to appropriate root location
            switch binderItem.type {
            case .draftFolder:
                manuscript.rootFolder = folder
            case .researchFolder, .trashFolder:
                // Add as subfolder or handle separately
                manuscript.rootFolder.subfolders.append(folder)
            default:
                break
            }
        }

        // 7. Import snapshots if requested
        if options.importSnapshots {
            progress?(0.92, "Importing snapshots...")
            // Snapshot import logic here
        }

        progress?(1.0, "Import complete!")
        return manuscript
    }

    // MARK: - Private Methods

    private func validateBundle(at url: URL) throws {
        let fm = FileManager.default

        // Check it's a directory
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw ImportError.notABundle
        }

        // Check for project.scrivx
        let scrivxPath = url.appendingPathComponent("project.scrivx")
        guard fm.fileExists(atPath: scrivxPath.path) else {
            throw ImportError.missingProjectFile
        }
    }

    private func detectVersion(at url: URL) -> ScrivenerVersion {
        let dataPath = url.appendingPathComponent("Files/Data")
        return FileManager.default.fileExists(atPath: dataPath.path) ? .v3 : .v2
    }

    private func countBinderItems(_ items: [ScrivenerBinderItem]) -> Int {
        items.reduce(0) { count, item in
            count + 1 + countBinderItems(item.children)
        }
    }

    private func convertBinderItem(
        _ item: ScrivenerBinderItem,
        projectURL: URL,
        contentPath: String,
        version: ScrivenerVersion,
        labelMap: [Int: ScrivenerLabel],
        statusMap: [Int: ScrivenerStatus],
        options: ImportOptions,
        onProgress: (Int) -> Void
    ) async throws -> ManuscriptFolder {

        var folder = ManuscriptFolder(title: item.title)
        folder.creationDate = item.created ?? Date()

        // Convert children recursively
        for (index, child) in item.children.enumerated() {
            if child.type == .text {
                // Convert to document
                let document = try await convertTextItem(
                    child,
                    projectURL: projectURL,
                    contentPath: contentPath,
                    version: version,
                    order: index,
                    labelMap: labelMap,
                    statusMap: statusMap
                )
                folder.documents.append(document)
                onProgress(1)
            } else if child.type == .folder || child.type == .draftFolder {
                // Convert to subfolder
                let subfolder = try await convertBinderItem(
                    child,
                    projectURL: projectURL,
                    contentPath: contentPath,
                    version: version,
                    labelMap: labelMap,
                    statusMap: statusMap,
                    options: options,
                    onProgress: onProgress
                )
                folder.subfolders.append(subfolder)
            }
            // Handle other types (PDF, Image, etc.) as needed
        }

        return folder
    }

    private func convertTextItem(
        _ item: ScrivenerBinderItem,
        projectURL: URL,
        contentPath: String,
        version: ScrivenerVersion,
        order: Int,
        labelMap: [Int: ScrivenerLabel],
        statusMap: [Int: ScrivenerStatus]
    ) async throws -> ManuscriptDocument.Document {

        // Load RTF content
        let contentURL: URL
        if version == .v3, let uuid = item.uuid {
            contentURL = projectURL
                .appendingPathComponent(contentPath)
                .appendingPathComponent(uuid)
                .appendingPathComponent("content.rtf")
        } else {
            contentURL = projectURL
                .appendingPathComponent(contentPath)
                .appendingPathComponent("\(item.id).rtf")
        }

        var markdownContent = ""
        if FileManager.default.fileExists(atPath: contentURL.path) {
            let rtfData = try Data(contentsOf: contentURL)
            markdownContent = try rtfConverter.convert(rtfData: rtfData)
        }

        // Load notes if available
        var notes = ""
        let notesURL = contentURL.deletingLastPathComponent()
            .appendingPathComponent(version == .v3 ? "notes.rtf" : "\(item.id)_notes.rtf")
        if FileManager.default.fileExists(atPath: notesURL.path) {
            let notesData = try Data(contentsOf: notesURL)
            notes = try rtfConverter.convert(rtfData: notesData)
        }

        // Create document
        return ManuscriptDocument.Document(
            id: UUID(),
            title: item.title,
            outline: item.synopsis ?? "",
            notes: notes,
            content: markdownContent,
            creationDate: item.created ?? Date(),
            order: order
        )
    }
}

// MARK: - Import Options

struct ImportOptions {
    var importSnapshots: Bool = true
    var importTrash: Bool = false
    var importResearch: Bool = true
    var preserveScrivenerIDs: Bool = false  // Store original IDs in metadata

    static let `default` = ImportOptions()
}
```

### 4.2 ScrivenerXMLParser

```swift
// ScrivenerXMLParser.swift

import Foundation

/// Parses Scrivener project.scrivx XML files
class ScrivenerXMLParser: NSObject, XMLParserDelegate {

    // MARK: - Properties

    private var project: ScrivenerProject?
    private var currentElement = ""
    private var currentText = ""

    private var binderItems: [ScrivenerBinderItem] = []
    private var itemStack: [ScrivenerBinderItem] = []

    private var labels: [ScrivenerLabel] = []
    private var statuses: [ScrivenerStatus] = []

    private var projectTitle = ""
    private var draftTarget: Int?
    private var sessionTarget: Int?

    // Current parsing context
    private var currentItemID: String?
    private var currentItemUUID: String?
    private var currentItemType: String?
    private var currentItemTitle: String?
    private var currentItemCreated: Date?
    private var currentItemModified: Date?
    private var currentItemSynopsis: String?
    private var currentItemLabelID: Int?
    private var currentItemStatusID: Int?
    private var currentItemIncludeInCompile: Bool = true
    private var currentChildren: [[ScrivenerBinderItem]] = []

    // MARK: - Public Methods

    func parse(projectURL: URL) throws -> ScrivenerProject {
        guard let parser = XMLParser(contentsOf: projectURL) else {
            throw ImportError.xmlParsingFailed("Could not create XML parser")
        }

        parser.delegate = self

        guard parser.parse() else {
            throw ImportError.xmlParsingFailed(parser.parserError?.localizedDescription ?? "Unknown error")
        }

        return ScrivenerProject(
            title: projectTitle.isEmpty ? "Untitled" : projectTitle,
            version: .v3,  // Determined later by file structure
            binderItems: binderItems,
            labels: labels,
            statuses: statuses,
            targets: ScrivenerTargets(
                draftWordCount: draftTarget,
                sessionWordCount: sessionTarget,
                deadline: nil
            ),
            customMetadata: []
        )
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String]) {

        currentElement = elementName
        currentText = ""

        switch elementName {
        case "BinderItem":
            // Start new binder item
            currentItemID = attributes["ID"]
            currentItemUUID = attributes["UUID"]
            currentItemType = attributes["Type"]
            currentItemCreated = parseDate(attributes["Created"])
            currentItemModified = attributes["Modified"].flatMap { parseDate($0) }
            currentChildren.append([])

        case "Label":
            // Parse label definition
            if let idStr = attributes["ID"], let id = Int(idStr) {
                let colorStr = attributes["Color"] ?? ""
                labels.append(ScrivenerLabel(
                    id: id,
                    name: "",  // Will be set from element text
                    color: parseColor(colorStr)
                ))
            }

        case "Status":
            if let idStr = attributes["ID"], let id = Int(idStr) {
                statuses.append(ScrivenerStatus(id: id, name: ""))
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {

        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "ProjectTitle":
            projectTitle = trimmedText

        case "Title":
            if currentItemID != nil {
                currentItemTitle = trimmedText
            }

        case "Synopsis":
            currentItemSynopsis = trimmedText

        case "LabelID":
            currentItemLabelID = Int(trimmedText)

        case "StatusID":
            currentItemStatusID = Int(trimmedText)

        case "IncludeInCompile":
            currentItemIncludeInCompile = (trimmedText.lowercased() == "yes")

        case "DraftTarget":
            draftTarget = Int(trimmedText)

        case "SessionTarget":
            sessionTarget = Int(trimmedText)

        case "BinderItem":
            // Complete current binder item
            let item = ScrivenerBinderItem(
                id: currentItemID ?? "",
                uuid: currentItemUUID,
                type: ScrivenerItemType(rawValue: currentItemType ?? "") ?? .text,
                title: currentItemTitle ?? "Untitled",
                created: currentItemCreated,
                modified: currentItemModified,
                synopsis: currentItemSynopsis,
                labelID: currentItemLabelID,
                statusID: currentItemStatusID,
                includeInCompile: currentItemIncludeInCompile,
                children: currentChildren.popLast() ?? [],
                targetWordCount: nil
            )

            // Add to parent's children or to root
            if var lastChildren = currentChildren.popLast() {
                lastChildren.append(item)
                currentChildren.append(lastChildren)
            } else {
                binderItems.append(item)
            }

            // Reset current item
            currentItemID = nil
            currentItemUUID = nil
            currentItemType = nil
            currentItemTitle = nil
            currentItemCreated = nil
            currentItemModified = nil
            currentItemSynopsis = nil
            currentItemLabelID = nil
            currentItemStatusID = nil
            currentItemIncludeInCompile = true

        case "Label":
            // Update last label with name
            if !labels.isEmpty {
                labels[labels.count - 1] = ScrivenerLabel(
                    id: labels.last!.id,
                    name: trimmedText,
                    color: labels.last!.color
                )
            }

        case "Status":
            if !statuses.isEmpty {
                statuses[statuses.count - 1] = ScrivenerStatus(
                    id: statuses.last!.id,
                    name: trimmedText
                )
            }

        default:
            break
        }
    }

    // MARK: - Helpers

    private func parseDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate]

        return formatter.date(from: string)
    }

    private func parseColor(_ colorString: String) -> Color {
        // Scrivener uses "R G B" format with 0-1 floats
        let components = colorString.split(separator: " ").compactMap { Double($0) }
        guard components.count >= 3 else { return .gray }

        return Color(
            red: components[0],
            green: components[1],
            blue: components[2]
        )
    }
}
```

### 4.3 RTFToMarkdownConverter

```swift
// RTFToMarkdownConverter.swift

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Converts RTF data to Markdown text
class RTFToMarkdownConverter {

    // MARK: - Public Methods

    func convert(rtfData: Data) throws -> String {
        // Use Foundation's RTF support
        #if canImport(AppKit)
        guard let attributedString = NSAttributedString(
            rtf: rtfData,
            documentAttributes: nil
        ) else {
            throw ImportError.rtfConversionFailed("Could not parse RTF data")
        }
        #elseif canImport(UIKit)
        guard let attributedString = try? NSAttributedString(
            data: rtfData,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            throw ImportError.rtfConversionFailed("Could not parse RTF data")
        }
        #endif

        return convertAttributedStringToMarkdown(attributedString)
    }

    // MARK: - Private Methods

    private func convertAttributedStringToMarkdown(_ attrString: NSAttributedString) -> String {
        var result = ""
        let string = attrString.string

        // Process the string character by character, tracking formatting
        var currentIndex = string.startIndex

        attrString.enumerateAttributes(
            in: NSRange(location: 0, length: attrString.length),
            options: []
        ) { attrs, range, _ in

            let nsRange = range
            guard let swiftRange = Range(nsRange, in: string) else { return }
            var text = String(string[swiftRange])

            // Check for bold
            if let font = attrs[.font] as? NSFont {
                let traits = font.fontDescriptor.symbolicTraits

                let isBold = traits.contains(.bold)
                let isItalic = traits.contains(.italic)

                if isBold && isItalic {
                    text = "***\(text)***"
                } else if isBold {
                    text = "**\(text)**"
                } else if isItalic {
                    text = "*\(text)*"
                }
            }

            // Check for strikethrough
            if let strikethrough = attrs[.strikethroughStyle] as? Int,
               strikethrough != 0 {
                text = "~~\(text)~~"
            }

            // Check for links
            if let url = attrs[.link] as? URL {
                text = "[\(text)](\(url.absoluteString))"
            } else if let urlString = attrs[.link] as? String {
                text = "[\(text)](\(urlString))"
            }

            result += text
        }

        // Post-process: clean up formatting artifacts
        result = cleanupMarkdown(result)

        return result
    }

    private func cleanupMarkdown(_ text: String) -> String {
        var result = text

        // Merge adjacent formatting markers
        // e.g., "**word****another**" → "**word another**"
        result = result.replacingOccurrences(of: "****", with: " ")
        result = result.replacingOccurrences(of: "**  **", with: " ")
        result = result.replacingOccurrences(of: "** **", with: " ")

        // Clean up empty formatting
        result = result.replacingOccurrences(of: "****", with: "")
        result = result.replacingOccurrences(of: "**", with: "", options: [], range: nil)

        // Normalize line endings
        result = result.replacingOccurrences(of: "\r\n", with: "\n")
        result = result.replacingOccurrences(of: "\r", with: "\n")

        return result
    }
}
```

### 4.4 ImportError

```swift
// ImportError.swift

import Foundation

enum ImportError: LocalizedError {
    case notABundle
    case missingProjectFile
    case xmlParsingFailed(String)
    case rtfConversionFailed(String)
    case missingContent(itemID: String)
    case unsupportedVersion(String)
    case fileReadFailed(String)

    var errorDescription: String? {
        switch self {
        case .notABundle:
            return "The selected file is not a valid Scrivener project bundle."
        case .missingProjectFile:
            return "Could not find project.scrivx in the Scrivener bundle."
        case .xmlParsingFailed(let detail):
            return "Failed to parse project file: \(detail)"
        case .rtfConversionFailed(let detail):
            return "Failed to convert RTF content: \(detail)"
        case .missingContent(let itemID):
            return "Could not find content for document \(itemID)."
        case .unsupportedVersion(let version):
            return "Scrivener version \(version) is not supported."
        case .fileReadFailed(let path):
            return "Failed to read file: \(path)"
        }
    }
}
```

---

## 5. UI Integration

### 5.1 Import Entry Points

**Welcome Screen:**
```swift
// Add to WelcomeView.swift

Button("Import from Scrivener...") {
    isShowingScrivenerImporter = true
}

.fileImporter(
    isPresented: $isShowingScrivenerImporter,
    allowedContentTypes: [UTType(filenameExtension: "scriv")!],
    allowsMultipleSelection: false
) { result in
    switch result {
    case .success(let urls):
        if let url = urls.first {
            importScrivenerProject(url: url)
        }
    case .failure(let error):
        showError(error)
    }
}
```

**Menu Bar (macOS):**
```swift
// Add to Commands
CommandGroup(replacing: .newItem) {
    Button("New Project...") { ... }
    Button("Open...") { ... }
    Divider()
    Button("Import from Scrivener...") {
        showScrivenerImporter()
    }
    .keyboardShortcut("i", modifiers: [.command, .shift])
}
```

### 5.2 Import Progress View

```swift
// ImportProgressView.swift

import SwiftUI

struct ImportProgressView: View {
    @Binding var isPresented: Bool
    let importURL: URL
    @State private var progress: Double = 0
    @State private var status: String = "Preparing..."
    @State private var error: Error?
    @State private var importedDocument: ManuscriptDocument?

    var body: some View {
        VStack(spacing: 20) {
            Text("Importing Scrivener Project")
                .font(.headline)

            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .frame(width: 300)

            Text(status)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let error = error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()

                Button("Close") {
                    isPresented = false
                }
            }
        }
        .padding(40)
        .task {
            await performImport()
        }
    }

    private func performImport() async {
        let importer = ScrivenerImporter()

        do {
            importedDocument = try await importer.importProject(
                from: importURL,
                progress: { prog, stat in
                    Task { @MainActor in
                        self.progress = prog
                        self.status = stat
                    }
                }
            )

            // Success - close and open document
            isPresented = false
            // Notify parent to open the imported document

        } catch {
            self.error = error
        }
    }
}
```

---

## 6. Edge Cases & Error Handling

### 6.1 Known Edge Cases

| Case | Handling |
|------|----------|
| Empty documents | Create document with empty content |
| Missing RTF files | Log warning, create placeholder |
| Corrupt RTF | Skip content, preserve metadata |
| Non-Latin characters | UTF-8 encoding throughout |
| Very large projects (1000+ docs) | Batched processing, progress updates |
| Scrivener 1.x projects | Detect and show "unsupported" message |
| iOS Scrivener projects | Same .scriv format, should work |
| Windows Scrivener (.scrivx only) | Support if project.scrivx present |

### 6.2 Validation Steps

```swift
extension ScrivenerImporter {

    func validateProject(at url: URL) throws -> ValidationResult {
        var warnings: [String] = []
        var errors: [String] = []

        // 1. Check bundle structure
        let fm = FileManager.default

        guard fm.fileExists(atPath: url.appendingPathComponent("project.scrivx").path) else {
            errors.append("Missing project.scrivx file")
            return ValidationResult(isValid: false, warnings: warnings, errors: errors)
        }

        // 2. Check for content directory
        let hasV3Data = fm.fileExists(atPath: url.appendingPathComponent("Files/Data").path)
        let hasV2Docs = fm.fileExists(atPath: url.appendingPathComponent("Files/Docs").path)

        if !hasV3Data && !hasV2Docs {
            errors.append("No content directory found (Files/Data or Files/Docs)")
        }

        // 3. Parse and count items
        let project = try xmlParser.parse(projectURL: url.appendingPathComponent("project.scrivx"))
        let itemCount = countBinderItems(project.binderItems)

        if itemCount > 500 {
            warnings.append("Large project (\(itemCount) items) - import may take a while")
        }

        // 4. Check for unsupported content
        let hasMedia = checkForMediaContent(project.binderItems)
        if hasMedia {
            warnings.append("Some media files (images, PDFs) will be copied but may need manual review")
        }

        return ValidationResult(
            isValid: errors.isEmpty,
            warnings: warnings,
            errors: errors
        )
    }
}

struct ValidationResult {
    let isValid: Bool
    let warnings: [String]
    let errors: [String]
}
```

---

## 7. Testing Strategy

### 7.1 Test Files Needed

Create or obtain test Scrivener projects:

```
TestProjects/
├── simple_project.scriv/          # Basic: 3 chapters, no nesting
├── nested_project.scriv/          # Deep nesting: 4+ levels
├── formatted_text.scriv/          # RTF: bold, italic, links
├── large_project.scriv/           # 100+ documents
├── v2_project.scriv/              # Scrivener 2 format
├── v3_project.scriv/              # Scrivener 3 format
├── unicode_project.scriv/         # Non-Latin characters
├── media_project.scriv/           # Images, PDFs embedded
└── empty_docs.scriv/              # Empty documents
```

### 7.2 Unit Tests

```swift
// ScrivenerImporterTests.swift

import XCTest
@testable import Manuscript

class ScrivenerImporterTests: XCTestCase {

    var importer: ScrivenerImporter!

    override func setUp() {
        super.setUp()
        importer = ScrivenerImporter()
    }

    func testValidateValidBundle() throws {
        let url = Bundle.module.url(forResource: "simple_project", withExtension: "scriv")!
        let result = try importer.validateProject(at: url)
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testParseSimpleProject() async throws {
        let url = Bundle.module.url(forResource: "simple_project", withExtension: "scriv")!
        let document = try await importer.importProject(from: url)

        XCTAssertEqual(document.title, "Simple Project")
        XCTAssertEqual(document.rootFolder.documents.count, 3)
    }

    func testParseNestedFolders() async throws {
        let url = Bundle.module.url(forResource: "nested_project", withExtension: "scriv")!
        let document = try await importer.importProject(from: url)

        XCTAssertFalse(document.rootFolder.subfolders.isEmpty)
        XCTAssertFalse(document.rootFolder.subfolders[0].subfolders.isEmpty)
    }

    func testRTFConversion() throws {
        let converter = RTFToMarkdownConverter()

        // Test bold
        let boldRTF = "{\\rtf1 \\b Hello\\b0  World}".data(using: .utf8)!
        let boldMD = try converter.convert(rtfData: boldRTF)
        XCTAssertTrue(boldMD.contains("**Hello**"))

        // Test italic
        let italicRTF = "{\\rtf1 \\i Hello\\i0  World}".data(using: .utf8)!
        let italicMD = try converter.convert(rtfData: italicRTF)
        XCTAssertTrue(italicMD.contains("*Hello*"))
    }
}
```

---

## 8. Implementation Phases

### Phase 1: Core Parser (Week 1)

**Deliverables:**
- [ ] `ScrivenerModels.swift` - Data structures
- [ ] `ScrivenerXMLParser.swift` - XML parsing
- [ ] `ImportError.swift` - Error types
- [ ] Unit tests for parser

**Success Criteria:**
- Can parse `project.scrivx` from any Scrivener 3 project
- Correctly builds binder item hierarchy
- Extracts labels, statuses, and targets

### Phase 2: Content Conversion (Week 2)

**Deliverables:**
- [ ] `RTFToMarkdownConverter.swift` - RTF conversion
- [ ] Content loading for Scrivener 2 and 3 formats
- [ ] Unit tests for RTF conversion

**Success Criteria:**
- Converts RTF to readable Markdown
- Preserves bold, italic, links
- Handles Unicode text correctly

### Phase 3: Integration (Week 3)

**Deliverables:**
- [ ] `ScrivenerImporter.swift` - Main import orchestrator
- [ ] Complete mapping to ManuscriptDocument
- [ ] Progress reporting
- [ ] Integration tests

**Success Criteria:**
- Full end-to-end import works
- Progress is reported accurately
- All document content is preserved

### Phase 4: UI & Polish (Week 4)

**Deliverables:**
- [ ] `ImportProgressView.swift` - Progress UI
- [ ] File importer integration in WelcomeView
- [ ] Menu bar integration (macOS)
- [ ] User-facing error messages

**Success Criteria:**
- Users can import via UI
- Progress is displayed during import
- Errors are shown clearly

---

## 9. Future Enhancements

### 9.1 Not In Scope (v1)

- Compile settings import
- Custom metadata fields
- Split document markers
- Inline annotations (as comments)
- Scrivener links between documents
- Collections import

### 9.2 Potential v2 Features

- **Bidirectional sync**: Export back to .scriv format
- **Live preview**: Preview import before committing
- **Selective import**: Choose which folders/documents to import
- **Metadata preservation**: Store Scrivener IDs for round-trip
- **Compile preset import**: Map Scrivener compile to Manuscript export

---

## 10. Dependencies

### External Libraries (Optional)

| Library | Purpose | Alternative |
|---------|---------|-------------|
| None required | - | - |

The implementation uses only Foundation/AppKit/UIKit for:
- XML parsing (`XMLParser`)
- RTF conversion (`NSAttributedString`)
- File system operations (`FileManager`)

No external dependencies needed.

---

## Appendix A: Scrivener XML Reference

### BinderItem Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `ID` | String | Unique identifier (numeric in v2, UUID in v3) |
| `UUID` | String | UUID (Scrivener 3 only) |
| `Type` | String | Item type (see §1.3) |
| `Created` | Date | Creation timestamp |
| `Modified` | Date | Last modified timestamp |

### MetaData Elements

| Element | Type | Description |
|---------|------|-------------|
| `LabelID` | Int | Reference to label |
| `StatusID` | Int | Reference to status |
| `IncludeInCompile` | Bool | Include in compile |
| `Target` | Element | Word/character target |
| `CustomMetaData` | Element | User-defined fields |

---

## Appendix B: Color Mapping

Scrivener stores colors as RGB floats ("R G B"). Common mappings:

| Scrivener RGB | Hex | Manuscript Label |
|---------------|-----|------------------|
| `0.0 0.0 0.0` | #000000 | No Label |
| `1.0 0.0 0.0` | #FF0000 | Red |
| `0.0 1.0 0.0` | #00FF00 | Green |
| `0.0 0.0 1.0` | #0000FF | Blue |
| `1.0 1.0 0.0` | #FFFF00 | Yellow |
| `1.0 0.0 1.0` | #FF00FF | Purple |
| `0.0 1.0 1.0` | #00FFFF | Cyan |
| `1.0 0.5 0.0` | #FF8000 | Orange |
