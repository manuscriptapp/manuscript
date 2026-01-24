# Performance Audit Report

**Date:** January 2026
**Codebase:** Manuscript iOS/macOS App
**Total Lines Analyzed:** ~35,000 lines of Swift

---

## Executive Summary

This audit identifies performance bottlenecks in the Manuscript codebase across SwiftUI rendering, data model efficiency, and main thread operations. Issues are categorized by effort required and potential impact.

**Key Findings:**
- Incorrect `Equatable` implementation causing missed view updates
- Excessive `@Published` properties triggering unnecessary re-renders
- Uncached computed properties (word count) called repeatedly
- Regex objects recreated on every parsing call
- Synchronous file I/O on main thread

---

## Low-Hanging Fruit (Quick Wins)

These fixes require minimal code changes but provide significant performance improvements.

### 1. Fix ManuscriptFolder Equatable Implementation

**File:** `Manuscript/Models/ManuscriptFolder.swift:42-47`
**Effort:** 5 minutes
**Impact:** HIGH - Fixes missed view updates

**Problem:** The `Equatable` implementation ignores `documents` and `subfolders`, causing SwiftUI to skip re-renders when folder contents change.

```swift
// Current (broken)
static func == (lhs: ManuscriptFolder, rhs: ManuscriptFolder) -> Bool {
    lhs.id == rhs.id &&
    lhs.title == rhs.title &&
    lhs.iconName == rhs.iconName &&
    lhs.iconColor == rhs.iconColor
    // MISSING: documents and subfolders comparison
}
```

**Fix:**
```swift
static func == (lhs: ManuscriptFolder, rhs: ManuscriptFolder) -> Bool {
    lhs.id == rhs.id &&
    lhs.title == rhs.title &&
    lhs.iconName == rhs.iconName &&
    lhs.iconColor == rhs.iconColor &&
    lhs.documents == rhs.documents &&
    lhs.subfolders == rhs.subfolders
}
```

---

### 2. Cache NSRegularExpression Objects

**File:** `Manuscript/Services/MarkdownParser.swift:111-123`
**Effort:** 15 minutes
**Impact:** MEDIUM - 20-50ms savings per markdown paragraph

**Problem:** Regex objects are created on every call to `processInlineFormatting()`. NSRegularExpression compilation is expensive.

```swift
// Current (slow)
for (pattern, style) in patterns {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
    // ...
}
```

**Fix:** Add a static cache at the top of the enum:
```swift
enum MarkdownParser {
    /// Cached regex patterns for performance
    private static let regexCache: [String: NSRegularExpression] = {
        let patterns = [
            "\\*\\*\\*(.+?)\\*\\*\\*",
            "___(.+?)___",
            "\\*\\*(.+?)\\*\\*",
            "__(.+?)__",
            "\\*(.+?)\\*",
            "_(.+?)_",
            "~~(.+?)~~",
            "==(.+?)==",
        ]
        var cache: [String: NSRegularExpression] = [:]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                cache[pattern] = regex
            }
        }
        return cache
    }()

    // Then use: guard let regex = regexCache[pattern] else { continue }
}
```

---

### 3. Cache Word Count in Document Model

**File:** `Manuscript/Models/ManuscriptDocumentItem.swift:70-74`
**Effort:** 20 minutes
**Impact:** MEDIUM-HIGH - 10-100ms savings per large document access

**Problem:** `wordCount` is computed on every property access, splitting the entire content string each time.

```swift
// Current (slow for large documents)
var wordCount: Int {
    let words = content.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
    return words.count
}
```

**Fix:** Since `Document` is a struct, use a lazy caching pattern or compute on content change:
```swift
// Option A: Compute only when content changes (in didSet)
// Option B: Create a String extension for reuse:
extension String {
    var wordCount: Int {
        self.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}
// Note: split() is faster than components() + filter()
```

---

### 4. Remove Debug Print Statements

**File:** `Manuscript/ViewModels/DocumentDetailViewModel.swift:48`
**Effort:** 2 minutes
**Impact:** LOW - Reduces console noise and minor CPU overhead

```swift
// Remove this debug statement
print("selectedText updated: \(selectedText.count) chars, hasTextSelection: \(hasTextSelection)")
```

---

### 5. Use split() Instead of components() for Word Counting

**Multiple Files:** CompositionModeWindow.swift, DocumentDetailView.swift, etc.
**Effort:** 10 minutes
**Impact:** LOW-MEDIUM - 20-40% faster string splitting

```swift
// Before (slower)
content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count

// After (faster - single pass, no intermediate arrays)
content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
```

---

## Medium-Effort Improvements

These require more substantial changes but offer significant benefits.

### 6. Cache totalWordCount Calculation

**File:** `Manuscript/Models/ManuscriptFolder.swift:85-89`
**Effort:** 1-2 hours
**Impact:** HIGH - Prevents exponential performance degradation

**Problem:** `totalWordCount` recursively calculates word counts across all nested folders and documents. For a project with 100 documents across 10 folders, this triggers ~1000+ string operations per access.

```swift
// Current (exponential complexity)
var totalWordCount: Int {
    let documentWords = documents.reduce(0) { $0 + $1.wordCount }
    let subfolderWords = subfolders.reduce(0) { $0 + $1.totalWordCount }
    return documentWords + subfolderWords
}
```

**Fix:** Cache at the document level and invalidate on changes:
```swift
// In ManuscriptDocument, maintain a cached total:
private var _cachedWordCount: Int?

var totalWordCount: Int {
    if let cached = _cachedWordCount { return cached }
    let count = rootFolder.calculateTotalWordCount()
    _cachedWordCount = count
    return count
}

mutating func invalidateWordCountCache() {
    _cachedWordCount = nil
}
```

---

### 7. Move ICloud Status Checks to Background Thread

**File:** `Manuscript/Services/ICloudSyncService.swift:117-207`
**Effort:** 1 hour
**Impact:** MEDIUM - Eliminates 10-100ms main thread freezes

**Problem:** `checkStatus()` performs synchronous file I/O on the main thread via `url.resourceValues(forKeys:)` and `FileManager.default.fileExists()`.

```swift
// Current (blocking main thread)
private func checkStatus() {
    let resourceValues = try freshURL.resourceValues(forKeys: [...])
    // ...
    if FileManager.default.fileExists(atPath: url.path) { ... }
}
```

**Fix:** Move to a background task:
```swift
private func checkStatus() {
    Task.detached(priority: .utility) { [weak self] in
        guard let self = self else { return }
        guard let url = await self.monitoredURL else { return }

        let newStatus = self.calculateStatus(for: url)

        await MainActor.run {
            self.status = newStatus
        }
    }
}

private nonisolated func calculateStatus(for url: URL) -> ICloudSyncStatus {
    // All file I/O here, off main thread
}
```

---

### 8. Replace DispatchQueue.main.asyncAfter with Task.sleep

**Multiple Files:** 38 occurrences
**Effort:** 2-3 hours
**Impact:** LOW-MEDIUM - Cleaner code, better cancellation support

```swift
// Before
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    self.documentIdBeingRenamed = newDoc.id
}

// After
Task {
    try? await Task.sleep(for: .milliseconds(100))
    self.documentIdBeingRenamed = newDoc.id
}
```

---

### 9. Reduce @Published Properties in ViewModels

**Files:**
- `DocumentViewModel.swift` - 11 @Published properties
- `DocumentDetailViewModel.swift` - 15+ @Published properties

**Effort:** 2-4 hours
**Impact:** MEDIUM-HIGH - Reduces unnecessary SwiftUI re-renders

**Problem:** Every @Published property triggers `objectWillChange` for ALL subscribers, even if they don't use that property.

**Fix Options:**
1. Group related UI state into nested structs
2. Use `@State` for local-only UI state (like `showFindBar`)
3. Use `@Observable` macro (iOS 17+) for finer-grained updates

```swift
// Before: 15 @Published properties
@Published var showFindBar: Bool = false
@Published var showFindReplaceBar: Bool = false
@Published var isInspectorPresented: Bool = false
@Published var inspectorSelectedTab: Int = 0

// After: Group into UI state struct
struct UIState {
    var showFindBar: Bool = false
    var showFindReplaceBar: Bool = false
    var isInspectorPresented: Bool = false
    var inspectorSelectedTab: Int = 0
}
@Published var uiState = UIState()
```

---

## Larger Architectural Changes

These require significant refactoring but address fundamental performance issues.

### 10. Implement Folder Path Cache for O(1) Lookups

**File:** `Manuscript/ViewModels/DocumentViewModel.swift`
**Effort:** 4-8 hours
**Impact:** HIGH - Eliminates O(n) tree traversals

**Problem:** Multiple methods traverse the entire folder hierarchy for each operation:
- `findAncestorIdsForFolder()` - O(n)
- `findAncestorIdsForDocument()` - O(n)
- `findDocument()` - O(n)
- `findFolder()` - O(n)
- `folderHierarchyContaining()` - Called 3x per operation

**Current:** `addFolder()` does 5-6 full tree traversals for a single operation.

**Fix:** Maintain a lookup cache:
```swift
private var documentIdToParentFolder: [UUID: UUID] = [:]
private var folderIdToPath: [UUID: [UUID]] = [:]

private func rebuildCache() {
    documentIdToParentFolder.removeAll()
    folderIdToPath.removeAll()
    buildCache(folder: rootFolder, path: [])
    buildCache(folder: researchFolder, path: [])
    buildCache(folder: trashFolder, path: [])
}

private func buildCache(folder: ManuscriptFolder, path: [UUID]) {
    let newPath = path + [folder.id]
    folderIdToPath[folder.id] = newPath
    for doc in folder.documents {
        documentIdToParentFolder[doc.id] = folder.id
    }
    for subfolder in folder.subfolders {
        buildCache(folder: subfolder, path: newPath)
    }
}
```

---

### 11. Reduce Copy-on-Write Overhead

**File:** `Manuscript/ViewModels/DocumentViewModel.swift`
**Effort:** 8-16 hours
**Impact:** MEDIUM-HIGH - Reduces memory churn

**Problem:** Pattern repeated 50+ times:
```swift
func updateDocument(...) {
    var doc = document  // COPY entire document
    doc.rootFolder = updateDocumentInFolder(...)  // More copies
    doc.researchFolder = updateDocumentInFolder(...)
    doc.trashFolder = updateDocumentInFolder(...)
    document = doc  // COPY back
}
```

For large projects, this copies the entire data structure (folders, documents, characters, locations) multiple times per operation.

**Fix Options:**
1. Use in-place mutation with `inout` parameters
2. Consider reference types for mutable containers
3. Implement targeted update paths that only touch changed nodes

---

### 12. Implement Lazy View Loading for Large Outlines

**Files:** `OutlineView.swift`, `OutlineRowView.swift`
**Effort:** 4-8 hours
**Impact:** MEDIUM - Better performance for projects with 500+ documents

**Current State:** Already uses `LazyVStack` (good!)

**Improvement:** Consider virtualization for extremely large projects:
- Only render visible rows + buffer
- Recycle row views
- Implement estimated row heights

---

## Priority Matrix

| Priority | Issue | Effort | Impact | Files |
|----------|-------|--------|--------|-------|
| P0 | Fix ManuscriptFolder Equatable | 5 min | HIGH | ManuscriptFolder.swift:42-47 |
| P0 | Cache NSRegularExpression | 15 min | MEDIUM | MarkdownParser.swift:111-123 |
| P1 | Cache totalWordCount | 1-2 hr | HIGH | ManuscriptFolder.swift:85-89 |
| P1 | Move iCloud checks to background | 1 hr | MEDIUM | ICloudSyncService.swift:117-207 |
| P1 | Cache wordCount per document | 20 min | MEDIUM | ManuscriptDocumentItem.swift:70-74 |
| P2 | Implement folder path cache | 4-8 hr | HIGH | DocumentViewModel.swift |
| P2 | Reduce @Published properties | 2-4 hr | MEDIUM | DocumentDetailViewModel.swift |
| P2 | Use split() for word counting | 10 min | LOW | Multiple files |
| P3 | Replace asyncAfter with Task.sleep | 2-3 hr | LOW | Multiple files |
| P3 | Reduce copy-on-write overhead | 8-16 hr | MEDIUM | DocumentViewModel.swift |

---

## Recommended Action Plan

### Phase 1: Quick Wins (1-2 hours total)
1. Fix `ManuscriptFolder` Equatable
2. Cache regex objects in MarkdownParser
3. Remove debug print statements
4. Use `split()` for word counting

### Phase 2: Core Fixes (4-6 hours total)
5. Implement word count caching
6. Move iCloud checks to background
7. Reduce @Published properties

### Phase 3: Architectural Improvements (16-32 hours total)
8. Implement folder path cache
9. Reduce copy-on-write overhead
10. Consider @Observable macro migration (iOS 17+)

---

## Metrics to Track

After implementing fixes, measure:
- Time to render outline with 100+ documents
- Time to save document changes
- Memory usage during editing
- Main thread blocking (use Instruments Time Profiler)
- SwiftUI view body evaluation count (use Self._printChanges())

---

## Notes

- The codebase already follows good practices in many areas (LazyVStack usage, proper @MainActor isolation)
- Most issues stem from the recursive folder structure and value-type semantics of Swift structs
- iOS 17's @Observable macro would solve many of the @Published issues but requires a minimum deployment target change
