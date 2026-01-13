# Manuscript Action Plan

*Last updated: January 2026*

This document outlines the prioritized next steps for Manuscript development, based on a comprehensive review of the codebase, existing planning documents, and competitive analysis.

---

## Executive Summary

Manuscript has a solid SwiftUI foundation and thorough planning documentation. The immediate priority is **fixing architectural issues** before adding new features, followed by **rich text formatting** and **Scrivener import** to reach feature parity with competitors.

**Timeline Overview:**
- **Now → Q1 2026**: Foundation fixes + basic rich text
- **Q2 2026**: Scrivener import + core UI features
- **Q3 2026**: Organization features + sync
- **Q4 2026+**: Advanced features + polish

---

## Phase 0: Critical Foundation Fixes (Immediate Priority)

These issues should be addressed **before** any new feature work to prevent compounding technical debt.

### 0.1 Fix DocumentGroup Architecture
**Priority: 🔴 Critical** | **Effort: 2-3 days** | **Reference: `DOCUMENTGROUP_AUDIT.md`**

- [ ] Convert `ManuscriptDocument` from class to struct
- [ ] Implement proper `FileDocument` semantics with value-type mutations
- [ ] Fix `@Binding` usage to work correctly with SwiftUI change detection
- [ ] Add unit tests for document save/load cycle

### 0.2 Consolidate Document Managers
**Priority: 🔴 Critical** | **Effort: 1-2 days**

- [ ] Merge `DocumentManager` and `ManuscriptViewModel` into single source of truth
- [ ] Remove duplicate state management
- [ ] Simplify document state synchronization

### 0.3 Update Deprecated APIs
**Priority: 🟡 Moderate** | **Effort: 1 day**

- [ ] Update `onChange(of:perform:)` to new iOS 17+ API signature
- [ ] Update iCloud container ID from "literati-ai" to "manuscript"
- [ ] Audit for other deprecated API usage

### 0.4 Add Basic Test Coverage
**Priority: 🟡 Moderate** | **Effort: 2-3 days**

- [ ] Add unit tests for `ManuscriptDocument` save/load
- [ ] Add unit tests for `DocumentManager` operations
- [ ] Add UI tests for basic editor workflow
- [ ] Set up CI to run tests on PR

---

## Phase 1: Rich Text Formatting (Q1 2026)

**Reference: `PLAN_TEXT_FORMATTING.md`**

This is the most requested feature gap vs competitors. The plan uses native iOS 26/macOS 26 `AttributedString` + `TextEditor` APIs.

### 1.1 Basic Formatting
**Target: February 2026** | **Effort: 2 weeks**

- [ ] Implement bold (⌘B), italic (⌘I), underline (⌘U) support
- [ ] Add formatting toolbar component
- [ ] Integrate with existing `MarkdownEditor` view
- [ ] Ensure keyboard shortcuts work on both iOS and macOS

### 1.2 Extended Formatting
**Target: March 2026** | **Effort: 2 weeks**

- [ ] Add font family selection
- [ ] Add font size controls
- [ ] Add text color picker
- [ ] Add highlight/background color

### 1.3 Markdown Interoperability
**Target: April 2026** | **Effort: 3 weeks**

- [ ] Implement Markdown → AttributedString parsing
- [ ] Implement AttributedString → Markdown serialization
- [ ] Ensure round-trip fidelity (no data loss)
- [ ] Add preview mode toggle

### 1.4 Persistence
**Target: April 2026** | **Effort: 1 week**

- [ ] Update `ManuscriptDocument` to handle attributed content
- [ ] Ensure backwards compatibility with plain Markdown files
- [ ] Add file format version handling

---

## Phase 2: Scrivener Import (Q2 2026)

**Reference: `SCRIVENER_IMPORT_PLAN.md`**

Critical for user acquisition - allows writers to migrate existing projects.

### 2.1 Core Parser
**Target: May 2026 Week 1-2** | **Effort: 2 weeks**

- [ ] Implement `.scriv` bundle structure parser
- [ ] Parse `project.scrivx` XML file
- [ ] Extract binder hierarchy (folders, documents)
- [ ] Map Scrivener UUIDs to Manuscript documents

### 2.2 Content Conversion
**Target: May 2026 Week 3** | **Effort: 1 week**

- [ ] Implement RTF → Markdown converter
- [ ] Handle common RTF formatting (bold, italic, lists)
- [ ] Preserve document metadata (synopsis, notes)
- [ ] Convert Scrivener labels/statuses

### 2.3 Integration & UI
**Target: May 2026 Week 4** | **Effort: 1 week**

- [ ] Add import UI (file picker, progress, preview)
- [ ] Handle import errors gracefully
- [ ] Add import report (what was converted, what was skipped)
- [ ] Write comprehensive import tests

---

## Phase 3: Core UI Features (Q2-Q3 2026)

These features are table-stakes for a serious writing app.

### 3.1 Split Editor
**Priority: High** | **Effort: 2 weeks**

- [ ] Implement horizontal split view
- [ ] Implement vertical split view
- [ ] Add drag-to-resize divider
- [ ] Support independent scrolling
- [ ] Platform-specific implementations (NSSplitView vs custom)

### 3.2 Composition Mode (Distraction-Free)
**Priority: High** | **Effort: 1 week**

- [ ] Implement fullscreen editor mode
- [ ] Hide all UI except text
- [ ] Add customizable background (color, texture)
- [ ] Add fade-in UI on mouse movement
- [ ] Keyboard shortcut to toggle (⌘⇧F or similar)

### 3.3 Snapshots (Version History)
**Priority: Medium** | **Effort: 2 weeks**

- [ ] Design snapshot storage format
- [ ] Implement auto-snapshot on significant changes
- [ ] Add manual "Take Snapshot" command
- [ ] Build snapshot browser UI
- [ ] Add diff view between snapshots
- [ ] Implement restore from snapshot

### 3.4 Search
**Priority: High** | **Effort: 2 weeks**

- [ ] Implement full-text search across project
- [ ] Add find-in-document (⌘F)
- [ ] Add find-and-replace
- [ ] Add search filters (by folder, by date, by status)
- [ ] Highlight matches in results

---

## Phase 4: Organization Features (Q3 2026)

### 4.1 Labels & Status
**Priority: Medium** | **Effort: 1 week**

- [ ] Add label model (name, color)
- [ ] Add status model (To Do, First Draft, Revised, Final, Done)
- [ ] Update document model to include label/status
- [ ] Add UI for setting label/status
- [ ] Add color indicators in binder

### 4.2 Cork Board View
**Priority: Medium** | **Effort: 2-3 weeks**

- [ ] Design card component (title, synopsis, status, label color)
- [ ] Implement grid layout view
- [ ] Add drag-and-drop reordering
- [ ] Support different card sizes
- [ ] Add keyboard navigation

### 4.3 Outliner View
**Priority: Medium** | **Effort: 2 weeks**

- [ ] Implement table/spreadsheet-style view
- [ ] Show columns: Title, Synopsis, Word Count, Status, Label
- [ ] Add column resizing and reordering
- [ ] Support inline editing
- [ ] Add sorting by column

---

## Phase 5: Sync & Export (Q3-Q4 2026)

### 5.1 CloudKit Sync
**Priority: High** | **Effort: 3-4 weeks**

- [ ] Set up CloudKit container properly
- [ ] Implement CKRecord mapping for documents
- [ ] Handle conflict resolution
- [ ] Add sync status indicators
- [ ] Test extensively across devices
- [ ] Handle offline/online transitions

### 5.2 Multi-Format Export
**Priority: High** | **Effort: 3-4 weeks**

- [ ] Implement compile/export UI (format selection, options)
- [ ] Add DOCX export (using native APIs or lightweight library)
- [ ] Add EPUB export
- [ ] Add HTML export
- [ ] Add LaTeX export
- [ ] Add Fountain export (for screenwriters)
- [ ] Add export templates/presets

---

## Phase 6: Advanced Features (Q4 2026+)

### 6.1 Research Folder
**Priority: Low** | **Effort: 2 weeks**

- [ ] Design research item model (PDFs, images, web links, notes)
- [ ] Implement file import for research
- [ ] Add in-app viewer for research materials
- [ ] Link research items to documents

### 6.2 Writing Statistics
**Priority: Low** | **Effort: 1-2 weeks**

- [ ] Track word count history per document
- [ ] Track writing sessions (time, words written)
- [ ] Add daily/weekly/monthly statistics view
- [ ] Add word count goals and deadlines
- [ ] Add progress visualization

### 6.3 AI Integration
**Priority: Medium** | **Effort: 2-3 weeks**

- [ ] Integrate Apple Foundation Models (on-device)
- [ ] Add writing suggestions
- [ ] Add grammar/style checking
- [ ] Implement BYOK (Bring Your Own Key) for external APIs
- [ ] Add AI settings/preferences UI

---

## Immediate Next Actions (This Week)

1. **Create a new branch** for Phase 0 foundation fixes
2. **Fix `ManuscriptDocument`** class → struct conversion
3. **Add basic test coverage** for document operations
4. **Update iCloud container ID** from literati-ai to manuscript
5. **Test on both iOS and macOS** after each fix

---

## Success Metrics

| Milestone | Target Date | Success Criteria |
|-----------|-------------|------------------|
| Foundation Fixes | End of Jan 2026 | All tests pass, no document corruption |
| Rich Text MVP | Mar 2026 | Bold/italic/underline working on iOS + macOS |
| Scrivener Import | May 2026 | Successfully import sample .scriv projects |
| Core Features | Jul 2026 | Split editor, search, composition mode |
| CloudKit Sync | Sep 2026 | Sync working across iPhone, iPad, Mac |
| Feature Parity | Dec 2026 | 80% of Scrivener core features |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| iOS 26 API changes | Medium | High | Monitor WWDC, have fallback plan |
| CloudKit complexity | High | Medium | Start with simple sync, iterate |
| Scope creep | High | Medium | Stick to this plan, defer nice-to-haves |
| Solo developer burnout | Medium | High | Focus on MVP, ship incrementally |
| RTF conversion edge cases | High | Low | Accept 90% fidelity, document limitations |

---

## Resources & References

- `meta/PLAN_TEXT_FORMATTING.md` - Detailed rich text implementation plan
- `meta/SCRIVENER_IMPORT_PLAN.md` - Complete import specification
- `meta/DOCUMENTGROUP_AUDIT.md` - Architecture issues and fixes
- `meta/FEATURE_PARITY.md` - Competitive analysis
- `meta/TRANSFORMATION_GUIDE.md` - Codebase transformation roadmap

---

## Change Log

| Date | Change |
|------|--------|
| Jan 2026 | Initial action plan created |
