# Manuscript Action Plan

*Last updated: January 27, 2026*

This document outlines the prioritized next steps for Manuscript development. **Near feature parity with Scrivener achieved.**

---

## Executive Summary

Manuscript has achieved near-complete feature parity with Scrivener. Most core features are **complete** including rich text editing, split editor, corkboard, outliner, snapshots, trash folder, and comprehensive export options.

**Progress Update (Jan 27):**
- ✅ Rich text editing complete (bold, italic, underline, fonts, sizes, colors)
- ✅ Formatting toolbar with undo/redo support
- ✅ Paragraph formatting (first-line indent, line spacing)
- ✅ Comments system with inline highlighting and inspector
- ✅ Scrivener import with RTF conversion and comments
- ✅ Drag-and-drop reordering and moving between folders
- ✅ Inline document renaming (Scrivener-style)
- ✅ State restoration and window persistence
- ✅ Find & replace with search highlighting
- ✅ Split editor (side-by-side documents on macOS)
- ✅ Snapshots (version history with restore)
- ✅ Corkboard view with index cards
- ✅ Outliner view with sortable columns
- ✅ Writing targets (draft and session goals)
- ✅ iCloud Drive sync
- ✅ Read mode (distraction-free reading)
- ✅ Trash folder (soft-delete with restore)
- ✅ Export: PDF, DOCX, EPUB, Markdown, Plain Text, Scrivener

**Remaining:**
- Composition mode (distraction-free writing)
- Print documents
- Import documents (Word, PDF, HTML)
- Document links
- Keywords/tags system

**Key Strategy**: Polish and prepare for launch.

---

## Sprint 1-4: Foundation & Rich Text ✅ COMPLETE

**Completed January 2026**

### Rich Text Editing ✅
- [x] Rich text formatting with RichTextKit
- [x] Bold (⌘B), Italic (⌘I), Underline (⌘U)
- [x] Font family and size selection
- [x] Text and highlight color pickers
- [x] Paragraph first-line indentation
- [x] Line spacing control
- [x] Formatting toolbar with undo/redo
- [x] Markdown ↔ AttributedString persistence

### Comments System ✅
- [x] Inline comment highlighting in editor
- [x] Comment inspector with chat bubble UI
- [x] Click-to-scroll comment navigation

### Scrivener Import ✅
- [x] `.scriv` bundle parser
- [x] `project.scrivx` XML parsing
- [x] Binder hierarchy extraction
- [x] RTF → Markdown converter
- [x] Comments import and parsing
- [x] Icon mapping from Scrivener
- [x] Import UI with file picker

### Organization ✅
- [x] Drag-and-drop reordering in sidebar
- [x] Drag-and-drop to move between folders
- [x] Inline document renaming (Scrivener-style)
- [x] State restoration (last document, expanded folders)
- [x] Window state persistence

---

## Sprint 5: Search & Polish ✅ COMPLETE

### Track A: Find & Replace ✅
- [x] Find-in-document (⌘F)
- [x] Find-and-replace
- [x] Search result highlighting
- [x] Navigate between matches

### Track B: Writing Targets ✅
- [x] Project targets
- [x] Session targets
- [x] Deadline tracking
- [x] Progress indicators

---

## Sprint 6: Core UI Features ✅ COMPLETE

### Track A: Split Editor ✅
- [x] Side-by-side document views (macOS)
- [x] Independent scrolling
- [x] Quick switch between documents

### Track B: Read Mode ✅
- [x] Distraction-free reading view
- [x] Prose typography
- [x] Clean interface

### Track C: Snapshots ✅
- [x] Snapshot storage format
- [x] Manual snapshot creation
- [x] Snapshot browser in inspector
- [x] Restore from snapshot

---

## Sprint 7: Organization + Sync ✅ COMPLETE

### Track A: Trash Folder ✅
- [x] Soft-delete (move to trash)
- [x] Restore from trash
- [x] Permanent delete
- [x] Empty trash

### Track B: Cork Board ✅
- [x] Card component design
- [x] Grid layout
- [x] Synopsis editing on cards
- [x] Visual organization

### Track C: Outliner ✅
- [x] Table view implementation
- [x] Sortable columns
- [x] Metadata display
- [x] Hierarchical structure

### Track D: iCloud Drive Sync ✅
- [x] Document-based iCloud sync
- [x] Cross-device access
- [x] Sync status indicator (macOS)

---

## Sprint 8: Export ✅ COMPLETE

### Multi-Format Export ✅
- [x] Compile/export UI
- [x] PDF export with customization
- [x] DOCX export
- [x] EPUB export
- [x] Markdown export
- [x] Plain Text export
- [x] Scrivener (.scriv) export
- [x] Exclude files from compile

---

## Sprint 9: Remaining Features (Current)

### Composition Mode
- [ ] Fullscreen distraction-free mode
- [ ] Customizable background
- [ ] Fade-in controls on hover

### Import
- [ ] Import DOCX
- [ ] Import PDF
- [ ] Import HTML
- [ ] Import images

### Organization
- [ ] Keywords/tags system
- [ ] Document links
- [ ] Collections/filtered views

### Polish
- [ ] Performance optimization
- [ ] Accessibility audit
- [ ] Print documents

---

## Sprint 9: Launch Prep (Jun)

### AI Enhancements (Already Partially Complete)
- [x] AI text generation service
- [x] Custom API key support (OpenAI, Anthropic)
- [ ] Apple Foundation Models integration
- [ ] Writing suggestions
- [ ] Grammar/style checking

### Launch Prep
- [ ] Final bug bash
- [ ] App Store screenshots + metadata
- [ ] Marketing site update
- [ ] **Launch v1.0**

---

## Progress Summary

```
Feature                    Status
========================= ========
Rich Text Editing          ✅ DONE
Formatting Toolbar         ✅ DONE
Paragraph Formatting       ✅ DONE
Comments System            ✅ DONE
Scrivener Import           ✅ DONE
Drag & Drop Reorder        ✅ DONE
Move Between Folders       ✅ DONE
Inline Renaming            ✅ DONE
State Restoration          ✅ DONE
AI Integration             ✅ DONE
Find & Replace             ✅ DONE
Writing Targets            ✅ DONE
Split Editor               ✅ DONE
Read Mode                  ✅ DONE
Cork Board                 ✅ DONE
Outliner                   ✅ DONE
iCloud Sync                ✅ DONE
Snapshots                  ✅ DONE
Trash Folder               ✅ DONE
Export (PDF/DOCX/EPUB)     ✅ DONE
Composition Mode           🔜 Planned
Import Documents           🔜 Planned
Keywords/Tags              🔜 Planned
Document Links             🔜 Planned
```

---

## Upcoming Milestones

| Target | Deliverable |
|--------|-------------|
| ~~Feb 2026~~ | ~~Find & replace, writing targets~~ ✅ |
| ~~Mar 2026~~ | ~~Split editor~~ ✅ |
| ~~Apr 2026~~ | ~~Snapshots, corkboard, outliner~~ ✅ |
| Feb 2026 | Composition mode, polish |
| Mar 2026 | Import documents, final testing |
| Apr 2026 | **v1.0 Launch**: Ready for App Store |

---

## Daily Standup Questions

1. What did I ship yesterday?
2. What am I shipping today?
3. What's blocking me?

**Rule**: If blocked for >2 hours, cut scope or find workaround. Ship something.

---

## Scope Cuts (If Behind Schedule)

If we fall behind, cut in this order:

1. **LaTeX/Fountain export** - Niche formats, add post-launch
2. **Research folder** - Users can use Finder/Files
3. **Writing statistics** - Nice-to-have, not core
4. **Cork board** - Outliner covers similar use case
5. **Advanced AI** - Basic suggestions sufficient for v1.0

**Never cut**: Rich text, Scrivener import, search, sync, basic export

---

## Success Metrics

| Metric | Target | Measure |
|--------|--------|---------|
| Time to feature parity | 22 weeks | Ship v1.0 by Jun 15 |
| Release cadence | Every 4 weeks | 5 releases before v1.0 |
| Test coverage | >70% | Unit + integration tests |
| Crash-free rate | >99% | TestFlight metrics |
| Scrivener import success | >95% | Test with 20 real projects |

---

## Immediate Actions (Next Steps)

1. [ ] Implement composition mode (distraction-free writing)
2. [ ] Add print document support
3. [ ] Implement document import (DOCX, PDF, HTML)
4. [ ] Add keywords/tags system
5. [ ] Prepare App Store assets (icons, screenshots, metadata)
6. [ ] Final performance audit and polish

---

## Resources

- `meta/PLAN_TEXT_FORMATTING.md` - Rich text details
- `meta/SCRIVENER_IMPORT_PLAN.md` - Import specification
- `meta/DOCUMENTGROUP_AUDIT.md` - Architecture fixes
- `meta/FEATURE_PARITY.md` - Competitive analysis

---

## Change Log

| Date | Change |
|------|--------|
| Jan 2026 | Initial action plan created |
| Jan 2026 | Compressed to aggressive 22-week timeline |
| Jan 22, 2026 | Updated: Rich text, comments, drag-drop, inline renaming, Scrivener import all complete |
| Jan 27, 2026 | Major update: Find & replace, split editor, corkboard, outliner, snapshots, trash folder, export formats, writing targets, iCloud sync all complete |
