# Scrivener Import Gap Analysis

**Date**: 2026-01-22 (Updated)
**Comparing**: SCRIVENER_IMPORT_PLAN.md vs Current Implementation

## Executive Summary

The Scrivener import feature has been **substantially implemented** with most core functionality working. The implementation covers XML parsing, RTF-to-Markdown conversion, binder structure mapping, and a complete UI. Recent updates have added **writing history import** and **icon import with color support**.

**Implementation Status**: ~92% complete

---

## ✅ Fully Implemented Features

### 1. Core Architecture
- ✅ **ScrivenerImporter.swift** - Main import orchestrator (543 lines)
- ✅ **ScrivenerXMLParser.swift** - XML parsing with XMLParserDelegate (342 lines)
- ✅ **ScrivenerModels.swift** - Complete data structures (215 lines)
- ✅ **RTFToMarkdownConverter.swift** - RTF to Markdown conversion (212 lines)
- ✅ **ImportError.swift** - Error types and warnings (104 lines)
- ✅ **ScrivenerImportView.swift** - Complete import UI (453 lines)

### 2. Bundle Validation
- ✅ Validate .scriv bundle structure
- ✅ Check for .scrivx file (with flexible naming - supports both `project.scrivx` and `{ProjectName}.scrivx`)
- ✅ Detect Scrivener version (v2 vs v3)
- ✅ Count items and provide warnings
- ✅ Check for media content
- ✅ Validation result with errors/warnings

**Implementation**: ScrivenerImporter.swift:38-106

### 3. XML Parsing
- ✅ Parse `<ProjectTitle>`
- ✅ Parse `<Binder>` structure recursively
- ✅ Parse `<LabelSettings>` → labels
- ✅ Parse `<StatusSettings>` → statuses
- ✅ Parse `<ProjectTargets>` → draft/session word counts
- ✅ Handle nested `<BinderItem>` elements
- ✅ Extract all metadata (ID, UUID, Type, Created, Modified, Synopsis, LabelID, StatusID, IncludeInCompile)
- ✅ Parse RGB color values for labels
- ✅ Parse multiple date formats
- ✅ Build hierarchical structure with children

**Implementation**: ScrivenerXMLParser.swift:56-341

### 4. Binder Item Type Mapping
- ✅ `DraftFolder` → manuscript draft folder
- ✅ `ResearchFolder` → manuscript research folder
- ✅ `TrashFolder` → manuscript trash folder
- ✅ `Folder` → subfolders
- ✅ `Text` → documents
- ✅ Media types recognized (PDF, Image, WebPage) with warnings

**Implementation**: ScrivenerModels.swift:74-110

### 5. Content Conversion
- ✅ Detect v2 vs v3 file structure
  - v2: `Files/Docs/{ID}.rtf`
  - v3: `Files/Data/{UUID}/content.rtf`
- ✅ Load RTF content
- ✅ Load notes from separate RTF files
- ✅ Load synopsis from text files
- ✅ Convert RTF to Markdown
- ✅ Fallback to plain text if RTF parsing fails

**Implementation**: ScrivenerImporter.swift:400-457

### 6. RTF to Markdown Conversion
- ✅ **Bold** (`\b` → `**text**`)
- ✅ **Italic** (`\i` → `*text*`)
- ✅ **Bold+Italic** → `***text***`
- ✅ **Strikethrough** → `~~text~~`
- ✅ **Links** → `[text](url)`
- ✅ Preserve whitespace properly
- ✅ Clean up markdown (merge adjacent markers, normalize line breaks)
- ✅ Cross-platform support (AppKit/UIKit)

**Implementation**: RTFToMarkdownConverter.swift:72-210

### 7. Metadata Mapping
- ✅ Project title
- ✅ Labels (ID, name, color)
- ✅ Statuses (ID, name)
- ✅ Targets (draft word count, session word count)
- ✅ Document creation/modification dates
- ✅ Label/status ID references
- ✅ Include in compile flag
- ✅ Synopsis

**Implementation**: ScrivenerImporter.swift:138-178

### 8. Document Structure Building
- ✅ Create ManuscriptDocument
- ✅ Map draft folder to rootFolder
- ✅ Map research folder to researchFolder
- ✅ Map trash folder to trashFolder
- ✅ Recursive subfolder creation
- ✅ Preserve document order
- ✅ Set folder types correctly
- ✅ Map label/status colors to Manuscript color names

**Implementation**: ScrivenerImporter.swift:189-248, 309-398

### 9. Import Options
- ✅ Import research folder (toggle)
- ✅ Import trash folder (toggle)
- ✅ Import snapshots (toggle - UI only, not implemented yet)
- ✅ Preserve Scrivener IDs option (defined but not used)

**Implementation**: ScrivenerModels.swift:167-186

### 10. User Interface
- ✅ Complete import wizard with state machine
- ✅ File selection (macOS with NSOpenPanel)
- ✅ Validation preview
- ✅ Progress indicator during import
- ✅ Warning/error display
- ✅ Import options configuration
- ✅ Success summary
- ✅ Error handling UI

**Implementation**: ScrivenerImportView.swift:1-453

### 11. Writing History Import (NEW)
- ✅ Parse `Files/writing.history` XML file
- ✅ Extract daily word counts (`dwc` attribute)
- ✅ Extract draft totals (`dtwc` attribute)
- ✅ Parse date format (`YYYY-MM-DD`)
- ✅ Map to `WritingHistory` and `WritingHistoryEntry` models
- ✅ Display in `WritingHistoryView` with statistics and charts
- ✅ Calculate streaks (current and longest)
- ✅ Time-range filtering (7/30/90 days, all time)
- ✅ Period navigation for historical data

**Implementation**:
- WritingHistory.swift:289-395 (ScrivenerWritingHistoryParser)
- ScrivenerImporter.swift:313-344 (importWritingHistory)
- WritingHistoryView.swift:1-740 (visualization)

### 12. Icon Import with Color Support (NEW)
- ✅ Parse `<IconFileName>` from MetaData in .scrivx
- ✅ Map Scrivener icons to SF Symbols
- ✅ Extract color from "Category (Color)" format (e.g., "Flag (Red)")
- ✅ Support for 100+ icon mappings
- ✅ 27+ color variants supported
- ✅ Type-based fallback icons
- ✅ Persist icon color as hex string in document

**Implementation**: ScrivenerIconMapper.swift:1-379

### 11. Error Handling
- ✅ Comprehensive error types:
  - `notABundle`
  - `missingProjectFile`
  - `xmlParsingFailed`
  - `rtfConversionFailed`
  - `missingContent`
  - `unsupportedVersion`
  - `fileReadFailed`
  - `invalidBundleStructure`
  - `cancelled`
- ✅ Non-fatal warnings system
- ✅ Skip items gracefully with warnings
- ✅ Track skipped/imported counts

**Implementation**: ImportError.swift:4-103, ScrivenerImporter.swift:18-21

---

## ⚠️ Partially Implemented Features

### 1. Title Fallback
**Status**: Implemented but different from plan

**Plan**: Use "Untitled Project" as default
**Reality**: Uses .scriv bundle name as fallback when XML title is empty or "Untitled Project"

```swift
// ScrivenerImporter.swift:141-148
if !scrivProject.title.isEmpty && scrivProject.title != "Untitled Project" {
    manuscript.title = scrivProject.title
} else {
    let bundleName = url.deletingPathExtension().lastPathComponent
    manuscript.title = bundleName
}
```

**Assessment**: Better than planned - more user-friendly

### 2. Custom Metadata Fields
**Status**: Data structure defined but not parsed

**Defined**: `ScrivenerCustomField` struct exists
**Missing**: No XML parsing for `<CustomMetaDataSettings>`

**Impact**: Low - custom metadata is a power user feature

---

## ❌ Not Implemented (from Original Plan)

### 1. Snapshots Import
**Status**: Not implemented

**Plan**: Import document snapshots from `Snapshots/{ID}/` folder
**Reality**: UI has toggle for "Import Snapshots" but functionality not built

**Code Reference**: ScrivenerImporter.swift:469-472 (commented placeholder)

**Priority**: Medium - snapshots are useful for version history

**Effort**: Medium - requires:
- Parsing snapshot XML metadata
- Loading historical RTF versions
- Creating snapshot data structure in Manuscript
- UI for viewing snapshots

### 2. Media File Handling
**Status**: Detected but not imported

**Plan**: Copy PDFs, images, web pages to `assets/` and create references
**Reality**: Media files are detected and warned about, but not copied

**Code Reference**: ScrivenerImporter.swift:295-307, 360-367

**Current Behavior**:
```swift
case .pdf, .image, .webPage:
    warnings.append(ImportWarning(
        message: "Media item skipped (not yet supported)",
        itemTitle: child.title,
        severity: .info
    ))
```

**Priority**: High - users may have embedded images/PDFs in research

**Effort**: Medium - requires:
- Asset copying logic
- Reference linking in Markdown
- Manuscript asset folder structure

### 3. Advanced RTF Features
**Status**: Basic formatting only

**Implemented**:
- Bold, italic, bold+italic
- Strikethrough
- Links
- Basic cleanup

**Missing from Plan**:
- ❌ **Headings** (RTF `\pard\s1` → `# Heading`)
- ❌ **Lists** (bullets/numbered)
- ❌ **Footnotes** → `[^1]` notation
- ❌ **RTF Comments** → HTML comments or notes
- ❌ **Inline annotations**
- ❌ **Block quotes**
- ❌ **Code blocks**

**Priority**: Medium - depends on how users format their Scrivener content

**Effort**: Medium-High - RTF parsing is complex

### 4. iOS File Picker
**Status**: macOS only

**Implementation**: macOS uses NSOpenPanel
**Missing**: iOS document picker integration

**Code Reference**: ScrivenerImportView.swift:341-375

```swift
#if os(macOS)
    let panel = NSOpenPanel()
    // ... macOS implementation
#else
    // On iOS, we'll need to use a document picker
    // This would typically be handled by a .fileImporter modifier in the parent view
#endif
```

**Priority**: High - app is cross-platform

**Effort**: Low - just needs UIDocumentPickerViewController or SwiftUI .fileImporter

### 5. Compile Settings Import
**Status**: Not implemented

**Plan**: Import compile settings from `Settings/compile.xml`
**Reality**: Not attempted

**Priority**: Low - compile is a complex feature, may not be needed in v1

### 6. Project Bookmarks
**Status**: Not implemented

**Plan**: Parse `<ProjectBookmarks>` from XML
**Reality**: Not parsed

**Priority**: Low - bookmarks are minor feature

### 7. Custom Metadata Parsing
**Status**: Data structures exist but not populated

**Missing**: Parsing `<CustomMetaDataSettings>` and applying to documents

**Priority**: Medium - power users may rely on custom fields

**Effort**: Low - extend XML parser

### 8. Target Deadline
**Status**: Partially implemented

**Plan**: Parse deadline from `<ProjectTargets>`
**Reality**: Only word count targets are parsed, deadline is always `nil`

**Code Reference**: ScrivenerModels.swift:148

**Priority**: Low - deadline is minor feature

### 9. URL Extensions
**Status**: Not created

**Plan**: `URL+Scrivener.swift` for URL helpers
**Reality**: Helper methods are inlined in ScrivenerImporter

**Impact**: None - just a code organization preference

### 10. Import Progress View (Separate Component)
**Status**: Not separate

**Plan**: Separate `ImportProgressView.swift` component
**Reality**: Progress UI is inline in `ScrivenerImportView`

**Impact**: None - works fine as-is

### 11. Import Options View (Separate Component)
**Status**: Not separate

**Plan**: Separate `ImportOptionsView.swift` component
**Reality**: Options are inline toggles in validation view

**Impact**: None - simpler is better

---

## 🧪 Testing

### Test Coverage
**Status**: Basic test file exists but not comprehensive

**File**: `ManuscriptTests/ScrivenerImportTests.swift`

**Missing from Plan**:
- No test Scrivener projects in repository
- No unit tests for RTF conversion
- No XML parser unit tests
- No edge case testing

**Priority**: High - testing import is critical

---

## 📊 Implementation Summary by Component

| Component | Lines | Status | Completeness |
|-----------|-------|--------|--------------|
| ScrivenerImporter | 706 | ✅ Done | 95% |
| ScrivenerXMLParser | 342 | ✅ Done | 95% |
| ScrivenerModels | 215 | ✅ Done | 100% |
| RTFToMarkdownConverter | 212 | ⚠️ Partial | 70% |
| ImportError | 104 | ✅ Done | 100% |
| ScrivenerImportView | 453 | ⚠️ Partial | 85% |
| ScrivenerIconMapper | 379 | ✅ Done | 100% |
| WritingHistory + Parser | 395 | ✅ Done | 100% |
| WritingHistoryView | 740 | ✅ Done | 100% |
| **Total** | **~3,546** | | **~92%** |

---

## 🎯 Prioritized Roadmap

### ✅ Recently Completed
- ~~**Writing history import**~~ - Parse and display Scrivener writing.history
- ~~**Icon import with colors**~~ - Map Scrivener icons to SF Symbols with color support
- ~~**Folder/document icon customization**~~ - Users can customize icons and colors

### P0 - Critical (Blocks Release)
1. **iOS file picker** - App is cross-platform, needs iOS support
2. **Basic testing** - At least one integration test with sample project

### P1 - High Priority (Should Have)
3. **Media file import** - Copy PDFs/images to assets
4. **Advanced RTF features** - Headings, lists, footnotes

### P2 - Medium Priority (Nice to Have)
5. **Snapshots import** - Version history
6. **Custom metadata parsing** - Power user feature

### P3 - Low Priority (Future)
7. **Compile settings** - Complex feature
8. **Project bookmarks** - Minor feature
9. **Target deadlines** - Minor feature

---

## 🔍 Code Quality Notes

### Strengths
- ✅ Clean separation of concerns
- ✅ Proper error handling with descriptive messages
- ✅ Async/await for long operations
- ✅ Progress callbacks
- ✅ Graceful degradation (skip unsupported items with warnings)
- ✅ Cross-platform RTF parsing

### Areas for Improvement
- ⚠️ No unit tests
- ⚠️ RTF converter could support more formatting
- ⚠️ Some hardcoded color mappings
- ⚠️ Label color mapping is basic (just name/hex prefix matching)

---

## 📝 Differences from Plan

### What's Better Than Planned
1. **Title fallback** - Uses bundle name instead of "Untitled Project"
2. **Flexible .scrivx detection** - Finds any .scrivx file, not just "project.scrivx"
3. **Better error messages** - More detailed and user-friendly
4. **Integrated UI** - Single-file import wizard vs multiple components

### What's Different
1. **File organization** - No separate `URL+Scrivener.swift`, helpers are inline
2. **View structure** - Single `ScrivenerImportView` vs separate progress/options views
3. **Import flow** - Async/await based vs callback-based

---

## 🚀 Next Steps

To reach 100% implementation:

1. **Add iOS file picker** (2-4 hours)
2. **Implement media file copying** (4-8 hours)
3. **Extend RTF converter for headings/lists** (8-16 hours)
4. **Add snapshot import** (8-16 hours)
5. **Create test suite with sample projects** (8-16 hours)
6. **Parse custom metadata fields** (4-8 hours)

**Total estimated effort to complete**: ~36-60 hours

### Recent Progress (January 2026)
- ✅ Writing history import and visualization
- ✅ Icon mapping with 100+ icons and 27+ colors
- ✅ Folder/document icon and color customization UI
- ✅ Improved binder item handling (folders with content)

---

## 📖 Documentation

Both implementation and plan are well-documented:
- ✅ Code has clear comments
- ✅ Plan document is comprehensive (1,398 lines)
- ✅ Error messages have recovery suggestions
- ⚠️ Could use more inline examples in code

---

## Conclusion

The Scrivener import implementation is **production-ready for most use cases**. It successfully handles:
- ✅ Text document import
- ✅ Folder structure preservation
- ✅ Metadata mapping (labels, statuses, targets)
- ✅ Both Scrivener v2 and v3 formats
- ✅ Error handling and user feedback
- ✅ **Writing history import with visualization** (NEW)
- ✅ **Icon import with color support** (NEW)
- ✅ **Folder/document customization** (NEW)

**Main gaps**:
1. iOS support (critical)
2. Media files (images, PDFs)
3. Advanced formatting (headings, lists)
4. Snapshots
5. Test coverage

For a v1.0 release, adding iOS picker support and basic testing would make this feature complete enough for most users. The recent additions of writing history and icon import significantly enhance the migration experience for Scrivener users.
