# Transformation Guide: Literati-AI to Manuscript

This document outlines how to transform the existing Literati-AI codebase into the Manuscript application described in the README.

## Executive Summary

| Aspect | Literati-AI (Current) | Manuscript (Target) |
|--------|----------------------|---------------------|
| **Licensing** | Commercial (closed) | MPL-2.0 (open source) |
| **Pricing** | Backend subscription | Free forever |
| **File Format** | Single JSON file (.literati) | Folder with Markdown (.manuscript/) |
| **Cloud Sync** | None | CloudKit (free) |
| **AI Integration** | External API (literati.tools) | Apple Foundation Models + BYOK |
| **Export** | PDF only | PDF, DOCX, EPUB, HTML, LaTeX, Fountain |
| **Core Features** | Character/Location management | Snapshots, Split editor, Composition mode |

---

## Phase 1: Foundation (Rebranding & File Format)

### 1.1 Rebranding

**Files to Update:**
- `literati_aiApp.swift` → `ManuscriptApp.swift`
- All references to "Literati" → "Manuscript"
- Bundle identifier: `com.dahlsjoo.literati` → `com.manuscriptapp.manuscript`
- UTType: `com.dahlsjoo.literati.document` → `com.manuscriptapp.manuscript`

**Tasks:**
- [ ] Rename app entry point and update `@main` struct
- [ ] Update Info.plist with new bundle identifier
- [ ] Update UTType declarations
- [ ] Replace all UI strings referencing "Literati"
- [ ] Update app icon and branding assets

### 1.2 File Format Migration

**Current Format (Literati):**
```
MyNovel.literati  (single JSON file)
```

**Target Format (Manuscript):**
```
MyNovel.manuscript/
├── project.json           # Project metadata
├── contents/
│   ├── draft/
│   │   ├── 01-chapter-one.md
│   │   └── 02-chapter-two.md
│   ├── notes/
│   └── research/
├── snapshots/
└── assets/
```

**Implementation Tasks:**
- [ ] Create new `ManuscriptProject` model as a folder-based FileWrapper
- [ ] Implement Markdown serialization for documents
- [ ] Create `project.json` schema for metadata only
- [ ] Build migration utility for existing `.literati` files
- [ ] Update `DocumentGroup` to use folder-based format

**New Models Required:**

```swift
// ManuscriptProject.swift
struct ManuscriptProject: FileDocument {
    static var readableContentTypes: [UTType] = [.manuscriptProject]

    var metadata: ProjectMetadata    // project.json
    var contents: FolderStructure    // contents/
    var snapshots: [Snapshot]        // snapshots/

    init(configuration: ReadConfiguration) throws {
        // Read from FileWrapper (folder)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Write as folder with Markdown files
    }
}

// ProjectMetadata.swift (project.json)
struct ProjectMetadata: Codable {
    var title: String
    var author: String
    var created: Date
    var modified: Date
    var settings: ProjectSettings
}
```

### 1.3 Markdown Editor

**Current State:**
- Plain TextEditor for content
- No Markdown rendering or syntax highlighting

**Target State:**
- Full Markdown editing with syntax highlighting
- Live preview option
- Standard Markdown files on disk

**Implementation Options:**
1. **Native SwiftUI** - Build custom Markdown editor
2. **Existing Library** - Integrate MarkdownUI or similar
3. **WebView** - Use WKWebView with CodeMirror/ProseMirror

**Recommended Approach:**
- Use native `TextEditor` with syntax highlighting overlay
- Add Markdown toolbar for common formatting
- Store as plain `.md` files

**Tasks:**
- [ ] Create `MarkdownEditorView` component
- [ ] Implement syntax highlighting (bold, italic, headers, links)
- [ ] Add formatting toolbar (iOS/macOS)
- [ ] Ensure files save as standard Markdown

---

## Phase 2: Core Features

### 2.1 Remove Character/Location Features

**Current State:**
- `LiteratiCharacter` model with name, age, gender
- `LiteratiLocation` model with coordinates
- Character/Location views and sheets
- Document-character/location associations

**Target State:**
- These features are not in the Manuscript roadmap
- May be added later as "Research folder" content

**Tasks:**
- [ ] Remove `LiteratiCharacter` and `LiteratiLocation` models
- [ ] Remove `CharactersView`, `LocationsView`, and related components
- [ ] Remove character/location sections from sidebar
- [ ] Simplify document model (remove `characterIds`, `locationIds`)
- [ ] Archive code for potential future "Research" feature

### 2.2 Snapshots (Version History)

**Current State:**
- No snapshot functionality

**Target State:**
- Automatic version history
- Manual snapshot creation
- Snapshot comparison and restoration

**Implementation:**

```swift
// Snapshot.swift
struct Snapshot: Codable, Identifiable {
    let id: UUID
    let date: Date
    let title: String
    let documentId: UUID
    let content: String  // Full Markdown content at snapshot time
    let isAutomatic: Bool
}

// SnapshotManager.swift
class SnapshotManager {
    func createSnapshot(for document: Document, title: String, automatic: Bool)
    func listSnapshots(for document: Document) -> [Snapshot]
    func restoreSnapshot(_ snapshot: Snapshot, to document: Document)
    func compareSnapshots(_ a: Snapshot, _ b: Snapshot) -> Diff
}
```

**Tasks:**
- [ ] Create Snapshot model
- [ ] Implement SnapshotManager
- [ ] Add automatic snapshot on significant changes (configurable interval)
- [ ] Create SnapshotListView for viewing history
- [ ] Implement snapshot comparison UI
- [ ] Add "Restore from Snapshot" functionality

### 2.3 Split Editor

**Current State:**
- Single document view only

**Target State:**
- View two documents side by side
- Horizontal or vertical split
- Independent scroll positions

**Implementation:**

```swift
// SplitEditorView.swift
struct SplitEditorView: View {
    @State var leftDocument: Document?
    @State var rightDocument: Document?
    @State var splitDirection: SplitDirection = .horizontal

    var body: some View {
        GeometryReader { geometry in
            if splitDirection == .horizontal {
                HStack(spacing: 1) {
                    EditorPane(document: $leftDocument)
                    Divider()
                    EditorPane(document: $rightDocument)
                }
            } else {
                VStack(spacing: 1) {
                    EditorPane(document: $leftDocument)
                    Divider()
                    EditorPane(document: $rightDocument)
                }
            }
        }
    }
}
```

**Tasks:**
- [ ] Create `SplitEditorView` component
- [ ] Add split toggle to toolbar
- [ ] Implement document selection for each pane
- [ ] Support horizontal and vertical split modes
- [ ] Persist split state per project

### 2.4 Composition Mode (Distraction-Free)

**Current State:**
- No fullscreen writing mode

**Target State:**
- Distraction-free fullscreen mode
- Customizable background color
- Typewriter scrolling option
- Focus on single paragraph option

**Implementation:**

```swift
// CompositionModeView.swift
struct CompositionModeView: View {
    @Binding var document: Document
    @State var backgroundColor: Color = .black
    @State var textColor: Color = .white
    @State var textWidth: CGFloat = 700
    @State var typewriterMode: Bool = true

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                TextEditor(text: $document.content)
                    .frame(maxWidth: textWidth)
                    .foregroundColor(textColor)
                    .scrollContentBackground(.hidden)
            }
        }
        .persistentSystemOverlays(.hidden)  // Hide system UI
    }
}
```

**Tasks:**
- [ ] Create `CompositionModeView`
- [ ] Add keyboard shortcut (Cmd+Shift+F) to enter composition mode
- [ ] Implement customizable theme (background, text color, width)
- [ ] Add typewriter scrolling (keep cursor centered)
- [ ] Add paragraph focus mode (dim other paragraphs)

---

## Phase 3: Organization Features

### 3.1 Project Binder Improvements

**Current State:**
- Basic folder/document hierarchy
- Drag-and-drop reordering (partial)

**Target State:**
- Full binder with Draft, Notes, Research, Trash sections
- Labels and status tags
- Icon customization
- Drag-and-drop between sections

**Tasks:**
- [ ] Add fixed top-level sections (Draft, Notes, Research, Trash)
- [ ] Implement label system (customizable colors/names)
- [ ] Add status tags (To Do, First Draft, Revised, Final)
- [ ] Improve drag-and-drop with visual feedback
- [ ] Add document icons (scene, chapter, folder, image, PDF)

### 3.2 Cork Board View

**Current State:**
- Not implemented

**Target State:**
- Visual card layout of documents
- Synopsis on cards
- Drag to reorder
- Color-coded by label

**Implementation:**

```swift
// CorkBoardView.swift
struct CorkBoardView: View {
    let documents: [Document]
    @State var columns: Int = 4

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns)) {
                ForEach(documents) { doc in
                    IndexCardView(document: doc)
                        .draggable(doc)
                }
            }
        }
    }
}

struct IndexCardView: View {
    let document: Document

    var body: some View {
        VStack(alignment: .leading) {
            Text(document.title)
                .font(.headline)
            Text(document.synopsis)
                .font(.caption)
                .lineLimit(5)
        }
        .padding()
        .background(document.label?.color ?? .white)
        .cornerRadius(4)
        .shadow(radius: 2)
    }
}
```

**Tasks:**
- [ ] Create `CorkBoardView` component
- [ ] Create `IndexCardView` for individual cards
- [ ] Implement drag-and-drop reordering
- [ ] Add view toggle (Binder / Cork Board / Outliner)
- [ ] Support multi-select operations

### 3.3 Outliner View

**Current State:**
- Not implemented

**Target State:**
- Spreadsheet-like view of documents
- Columns: Title, Synopsis, Word Count, Label, Status
- Inline editing
- Sortable columns

**Tasks:**
- [ ] Create `OutlinerView` component
- [ ] Implement sortable columns
- [ ] Add inline editing for synopsis
- [ ] Support bulk status/label changes
- [ ] Add word count column with targets

### 3.4 Search

**Current State:**
- No project-wide search

**Target State:**
- Search across all documents
- Filter by label, status, folder
- Replace functionality
- Regular expression support

**Tasks:**
- [ ] Implement `SearchService` with full-text search
- [ ] Create `SearchView` with results list
- [ ] Add search field to toolbar
- [ ] Implement Find & Replace
- [ ] Add search filters (label, status, date range)

---

## Phase 4: Sync & Export

### 4.1 CloudKit Sync

**Current State:**
- No cloud sync

**Target State:**
- Automatic sync via CloudKit
- No user account required (uses iCloud)
- Conflict resolution
- Offline support with sync on reconnect

**Implementation Approach:**
1. Use `NSPersistentCloudKitContainer` or manual CloudKit
2. Store projects in iCloud Drive container
3. Use `CKRecord` for metadata sync
4. Handle merge conflicts gracefully

**Tasks:**
- [ ] Enable CloudKit capability in Xcode
- [ ] Create CloudKit container (`iCloud.com.manuscriptapp.manuscript`)
- [ ] Implement `CloudKitSyncManager`
- [ ] Handle conflict resolution UI
- [ ] Add sync status indicator
- [ ] Test offline/online transitions

### 4.2 Export Formats

**Current State:**
- PDF export only

**Target State:**
- PDF, DOCX, EPUB, HTML, LaTeX, Fountain

**Implementation:**

```swift
// ExportService.swift
protocol ExportFormat {
    func export(project: ManuscriptProject, options: ExportOptions) throws -> Data
}

class PDFExporter: ExportFormat { ... }
class DOCXExporter: ExportFormat { ... }  // Use DocX library
class EPUBExporter: ExportFormat { ... }  // Use custom EPUB builder
class HTMLExporter: ExportFormat { ... }
class LaTeXExporter: ExportFormat { ... }
class FountainExporter: ExportFormat { ... }  // Screenplay format
```

**Tasks:**
- [ ] Refactor existing PDF export
- [ ] Implement DOCX export (consider ZIPFoundation + XML)
- [ ] Implement EPUB export (HTML + OPF + NCX)
- [ ] Implement HTML export (single file or folder)
- [ ] Implement LaTeX export (for academic users)
- [ ] Implement Fountain export (screenplay format)
- [ ] Create unified `CompileView` for export options

### 4.3 Import from Scrivener

**Current State:**
- No import functionality

**Target State:**
- Import `.scriv` projects
- Map Scrivener structure to Manuscript format
- Preserve metadata, labels, status

**Tasks:**
- [ ] Research Scrivener file format (XML-based)
- [ ] Create `ScrivenerImporter` class
- [ ] Map Scrivener binder to Manuscript folders
- [ ] Import document content (RTF → Markdown)
- [ ] Import metadata (labels, status, synopsis)
- [ ] Add import option to Welcome screen

---

## Phase 5: AI Integration

### 5.1 Remove External API Dependency

**Current State:**
- Uses `literati.tools/api` backend
- External server required for AI features
- Commercial API integration

**Target State:**
- Apple Foundation Models (on-device, free)
- Optional: Bring Your Own Key (OpenAI, Anthropic, etc.)
- No required external services

**Tasks:**
- [ ] Remove `APIService.swift` and `literati.tools` integration
- [ ] Remove `TextGenerationService.swift` external calls
- [ ] Create new `AIService` protocol

### 5.2 Apple Foundation Models Integration

**Implementation:**

```swift
// AppleAIService.swift
import FoundationModels  // iOS 18.4+ / macOS 15.4+

class AppleAIService: AIService {
    func generateText(prompt: String, context: String) async throws -> String {
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return response.content
    }

    func isAvailable() -> Bool {
        // Check device capability
        return LanguageModelSession.isAvailable
    }
}
```

**Tasks:**
- [ ] Add FoundationModels framework (when available)
- [ ] Create `AppleAIService` implementation
- [ ] Add capability check for older devices
- [ ] Create fallback UI when AI unavailable

### 5.3 Custom API Keys (BYOK)

**Implementation:**

```swift
// CustomAPIService.swift
class CustomAPIService: AIService {
    enum Provider: String, CaseIterable {
        case openai, anthropic, ollama
    }

    var provider: Provider
    var apiKey: String
    var baseURL: URL?  // For Ollama/custom endpoints

    func generateText(prompt: String, context: String) async throws -> String {
        switch provider {
        case .openai:
            return try await callOpenAI(prompt: prompt)
        case .anthropic:
            return try await callAnthropic(prompt: prompt)
        case .ollama:
            return try await callOllama(prompt: prompt)
        }
    }
}
```

**Tasks:**
- [ ] Create Settings UI for API key management
- [ ] Implement OpenAI API client
- [ ] Implement Anthropic API client
- [ ] Implement Ollama (local) API client
- [ ] Secure key storage in Keychain
- [ ] Add model selection per provider

### 5.4 AI Feature Simplification

**Current State:**
- Complex generation with styles (Formal, Casual, etc.)
- Chapter outline generation
- Chapter content generation

**Target State:**
- Simple, focused AI assistance
- Writing suggestions
- Grammar/style checking
- Summarization

**Tasks:**
- [ ] Simplify AI prompts
- [ ] Remove style-based generation
- [ ] Add inline suggestions UI
- [ ] Add "Improve writing" command
- [ ] Add "Summarize selection" command

---

## Code Removal Summary

### Files to Delete:
- `Services/APIService.swift` - External API client
- `Services/TextGenerationService.swift` - External generation
- `Views/Components/Character/` - Entire folder
- `Views/Components/Location/` - Entire folder
- `Models/LiteratiCharacter` parts of models
- `Models/LiteratiLocation` parts of models
- `ViewModels/BooksViewModel.swift` - Merge into main VM
- `Views/Components/Sheets/AddCharacterSheet.swift`
- `Views/Components/Sheets/AddLocationSheet.swift`

### Files to Heavily Modify:
- `LiteratiDocument.swift` → `ManuscriptProject.swift`
- `literati_aiApp.swift` → `ManuscriptApp.swift`
- `ProjectSidebar.swift` - Remove character/location sections
- `LiteratiProjectView.swift` → `ProjectView.swift`
- `DocumentDetailView.swift` - Simplify tabs

### Files to Keep (with modifications):
- `Views/Components/Document/` - Editor components
- `Views/Components/Book/` - Folder/document views
- `Views/Components/Sheets/AddDocumentSheet.swift`
- `Views/Components/Sheets/AddFolderSheet.swift`
- `Extensions/Color+Extensions.swift`

---

## Migration Checklist

### Phase 1: Foundation
- [ ] Rename project and bundle IDs
- [ ] Update all "Literati" references to "Manuscript"
- [ ] Implement folder-based file format
- [ ] Create Markdown serialization
- [ ] Build .literati → .manuscript migration tool
- [ ] Update license to MPL-2.0

### Phase 2: Core Features
- [ ] Remove character/location features
- [ ] Implement snapshots
- [ ] Implement split editor
- [ ] Implement composition mode

### Phase 3: Organization
- [ ] Improve binder with fixed sections
- [ ] Add labels and status
- [ ] Implement cork board view
- [ ] Implement outliner view
- [ ] Add project-wide search

### Phase 4: Sync & Export
- [ ] Implement CloudKit sync
- [ ] Add DOCX export
- [ ] Add EPUB export
- [ ] Add HTML export
- [ ] Add LaTeX export
- [ ] Add Fountain export
- [ ] Add Scrivener import

### Phase 5: AI
- [ ] Remove external API dependency
- [ ] Integrate Apple Foundation Models
- [ ] Add custom API key support
- [ ] Simplify AI features

---

## Estimated Effort

| Phase | Complexity | Estimated Work |
|-------|------------|----------------|
| Phase 1: Foundation | High | File format is significant work |
| Phase 2: Core | Medium | Standard SwiftUI features |
| Phase 3: Organization | Medium | UI-heavy but straightforward |
| Phase 4: Sync & Export | High | CloudKit and export formats complex |
| Phase 5: AI | Medium | Depends on Apple FM availability |

---

## Recommended Order

1. **Start with rebranding** - Quick win, establishes new identity
2. **File format migration** - Critical foundation, do early
3. **Remove character/location** - Simplifies codebase
4. **Add snapshots** - High value, moderate effort
5. **CloudKit sync** - Key differentiator from competitors
6. **Export formats** - Important for user adoption
7. **Split editor & composition mode** - Quality of life
8. **Cork board & outliner** - Nice to have
9. **AI integration** - Wait for Apple Foundation Models release

---

## Notes

- The current codebase is well-structured and can be evolved incrementally
- Folder-based file format is the biggest architectural change
- CloudKit sync requires careful conflict resolution design
- Apple Foundation Models availability will determine AI timeline
- Consider keeping character/location code archived for future "Research" feature
