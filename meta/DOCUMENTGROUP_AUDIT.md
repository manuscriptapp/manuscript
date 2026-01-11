# DocumentGroup Setup Audit Report

**Project:** Manuscript
**Date:** January 11, 2026
**Auditor:** Claude Code

---

## Executive Summary

The Manuscript app uses SwiftUI's `DocumentGroup` for document-based architecture. While the implementation is functional, there are several architectural concerns and deviations from Apple's recommended best practices that should be addressed to improve reliability, maintainability, and data integrity.

**Overall Assessment:** Functional but needs refactoring
**Risk Level:** Medium

---

## 1. Architecture Overview

### Current Implementation

```
ManuscriptApp.swift
    └── DocumentGroup(newDocument: ManuscriptDocument())
            └── ManuscriptProjectView(document: file.$document)
                    ├── DocumentManager (ObservableObject)
                    └── ManuscriptViewModel (ObservableObject)
```

### Files Reviewed

| File | Purpose |
|------|---------|
| `ManuscriptApp.swift` | App entry point with DocumentGroup |
| `ManuscriptDocument.swift` | FileDocument implementation |
| `DocumentManager.swift` | Document state management |
| `BooksViewModel.swift` | Additional document operations |
| `ManuscriptProjectView.swift` | Main document view |
| `Info.plist` | Document type declarations |
| `Manuscript.entitlements` | iCloud & sandbox settings |

---

## 2. Critical Issues

### 2.1 FileDocument is a Class (Not a Struct)

**Location:** `ManuscriptDocument.swift:21`

```swift
class ManuscriptDocument: FileDocument, Equatable, Codable { ... }
```

**Issue:** Apple's `FileDocument` protocol is designed for value types (structs). Using a class:
- Breaks SwiftUI's change detection mechanism
- Can cause missed saves when properties change
- Makes undo/redo functionality unreliable
- Violates the single source of truth principle

**Best Practice:** `FileDocument` should be a `struct` with value semantics.

**Risk:** HIGH - May cause data loss or missed autosaves.

---

### 2.2 Dual Document Manager Architecture

**Location:** `ManuscriptProjectView.swift:7-8`

```swift
@StateObject private var documentManager: DocumentManager
@StateObject private var manuscriptViewModel: ManuscriptViewModel
```

**Issue:** Two separate `ObservableObject` managers both hold copies of the document:
- Creates synchronization complexity
- Requires manual change propagation (line 91-96)
- Increases risk of state divergence
- Duplicates functionality across managers

**Current Sync Mechanism:**
```swift
.onReceive(manuscriptViewModel.objectWillChange) { _ in
    DispatchQueue.main.async {
        documentManager.objectWillChange.send()
        document = manuscriptViewModel.document
    }
}
```

**Best Practice:** Single source of truth - one manager should own document mutations.

**Risk:** MEDIUM - State synchronization bugs, potential data inconsistency.

---

### 2.3 Binding with Reference Type

**Location:** `ManuscriptProjectView.swift:6`

```swift
@Binding var document: ManuscriptDocument
```

**Issue:** Using `@Binding` with a class type doesn't behave as expected:
- Binding expects value semantics for change detection
- Mutations to class properties don't trigger binding updates
- Requires manual `objectWillChange` notifications

**Best Practice:** Use `@Binding` only with value types, or use `@ObservedObject` for classes.

**Risk:** MEDIUM - UI may not update when document changes.

---

### 2.4 iCloud Container ID Mismatch

**Location:** `Manuscript.entitlements:6-8`

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.dahlsjoo.literati-ai</string>
</array>
```

**Issue:** The iCloud container still references "literati-ai" instead of "manuscript".

**Best Practice:** iCloud container should match the app's bundle identifier for clarity.

**Risk:** LOW - Functional but confusing; may cause issues if literati-ai app exists.

---

## 3. Moderate Issues

### 3.1 Silent Decode Failures

**Location:** `ManuscriptDocument.swift:74-97`

```swift
if let documentData = try? decoder.decode(...) {
    // Use decoded data
} else {
    // Silently create empty document
}
```

**Issue:** If a document fails to decode, the app silently creates an empty document instead of alerting the user. This could cause perceived data loss.

**Best Practice:** Throw decoding errors to trigger the system's error handling UI.

---

### 3.2 Autosave Implementation is a No-Op

**Location:** `DocumentManager.swift:29-32`

```swift
private func autosave() {
    // This will be triggered automatically when document changes
    // The DocumentGroup manages the actual saving
}
```

**Issue:** The autosave debounce setup exists but does nothing. The comment is correct that DocumentGroup handles saving, but the debounce subscription is wasted computation.

**Best Practice:** Remove unused code or implement actual functionality.

---

### 3.3 Deprecated onChange API

**Location:** `ManuscriptProjectView.swift:86`

```swift
.onChange(of: document) { newDocument in ... }
```

**Issue:** Using deprecated single-parameter `onChange` (deprecated in iOS 17).

**Best Practice:** Use two-parameter version: `.onChange(of: document) { oldValue, newValue in ... }`

---

## 4. Info.plist Configuration

### Document Type Declaration - CORRECT

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Manuscript Document</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.manuscriptapp.manuscript</string>
        </array>
    </dict>
</array>
```

### UTType Export Declaration - CORRECT

```xml
<key>UTExportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>com.manuscriptapp.manuscript</string>
        <key>UTTypeConformsTo</key>
        <array>
            <string>public.data</string>
            <string>public.content</string>
        </array>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array>
                <string>manuscript</string>
            </array>
        </dict>
    </dict>
</array>
```

### Document Browser Support - CORRECT

```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
<key>UISupportsDocumentBrowser</key>
<true/>
```

---

## 5. UTType Definition

**Location:** `ManuscriptDocument.swift:6-10`

```swift
extension UTType {
    static var manuscriptDocument: UTType {
        UTType(exportedAs: "com.manuscriptapp.manuscript")
    }
}
```

**Status:** CORRECT - Properly defined as exported type matching Info.plist.

---

## 6. Entitlements Review

| Entitlement | Value | Status |
|-------------|-------|--------|
| App Sandbox | `true` | Correct |
| Network Client | `true` | Correct (for AI features) |
| User-selected files (read-write) | `true` | Correct |
| Downloads folder | `true` | Correct |
| iCloud (CloudKit) | `true` | Correct |
| iCloud Container | `literati-ai` | Needs update |

---

## 7. Recommendations

### Priority 1: Convert ManuscriptDocument to Struct

```swift
struct ManuscriptDocument: FileDocument {
    var title: String
    var author: String
    // ... other properties

    static var readableContentTypes: [UTType] { [.manuscriptDocument] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self)
        return FileWrapper(regularFileWithContents: data)
    }
}
```

### Priority 2: Consolidate to Single Document Manager

Remove `DocumentManager` and keep only `ManuscriptViewModel` (renamed to `DocumentViewModel`), or vice versa. The view should work with a single manager:

```swift
struct ManuscriptProjectView: View {
    @Binding var document: ManuscriptDocument
    @StateObject private var viewModel: DocumentViewModel

    init(document: Binding<ManuscriptDocument>) {
        _document = document
        _viewModel = StateObject(wrappedValue: DocumentViewModel())
    }
}
```

### Priority 3: Proper Error Handling for Decode Failures

```swift
init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
        throw CocoaError(.fileReadCorruptFile)
    }

    do {
        let decoded = try JSONDecoder().decode(ManuscriptDocumentData.self, from: data)
        // ... assign properties
    } catch {
        throw CocoaError(.fileReadCorruptFile)
    }
}
```

### Priority 4: Update iCloud Container ID

Change entitlements to use manuscript-specific container:
```xml
<string>iCloud.com.manuscriptapp.manuscript</string>
```

### Priority 5: Update Deprecated APIs

```swift
.onChange(of: document) { oldValue, newValue in
    // Handle change
}
```

---

## 8. Testing Recommendations

1. **Autosave Testing:** Make changes and force-quit the app to verify saves
2. **iCloud Sync Testing:** Test document sync across devices
3. **Undo/Redo Testing:** Verify undo stack works correctly
4. **Concurrent Edit Testing:** Open same document in multiple windows (macOS)
5. **Error Recovery:** Test corrupted file handling
6. **Memory Testing:** Profile for retain cycles between managers

---

## 9. Conclusion

The current DocumentGroup implementation is functional for basic use cases but has architectural issues that may cause problems at scale or in edge cases. The most critical issue is using a class for `FileDocument`, which fundamentally conflicts with SwiftUI's change detection and may cause data loss.

**Recommended Action:** Plan a refactoring sprint to address Priority 1-3 items before shipping to production.

---

## Appendix: Apple Documentation References

- [Creating a Document-Based App in SwiftUI](https://developer.apple.com/documentation/swiftui/creating-a-document-based-app-in-swiftui)
- [FileDocument Protocol](https://developer.apple.com/documentation/swiftui/filedocument)
- [Uniform Type Identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers)
- [Document-Based Apps](https://developer.apple.com/design/human-interface-guidelines/document-based-apps)
