# Manuscript Action Plan

*Last updated: January 22, 2026*

This document outlines the prioritized next steps for Manuscript development. **Aggressive timeline targeting feature parity by June 2026.**

---

## Executive Summary

Manuscript has made significant progress. Rich text editing, formatting toolbar, Scrivener import, comments system, drag-and-drop, and inline renaming are all **complete**. We're on track for **feature parity with Scrivener by June 2026**.

**Progress Update (Jan 22):**
- ✅ Rich text editing complete (bold, italic, underline, fonts, sizes, colors)
- ✅ Formatting toolbar with undo/redo support
- ✅ Paragraph formatting (first-line indent, line spacing)
- ✅ Comments system with inline highlighting and inspector
- ✅ Scrivener import with RTF conversion and comments
- ✅ Drag-and-drop reordering and moving between folders
- ✅ Inline document renaming (Scrivener-style)
- ✅ State restoration and window persistence

**Remaining Timeline:**
- **Now - Feb**: Find & replace, writing targets UI
- **Mar - Apr**: Core UI features (split editor, composition mode)
- **Apr - May**: CloudKit sync, advanced views (cork board, outliner)
- **May - Jun**: Export formats, polish, beta release

**Key Strategy**: Run multiple tracks in parallel. Ship incrementally.

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

## Sprint 5: Search & Polish (Feb - Mar)

**Current focus**

### Track A: Find & Replace (High Priority)
- [ ] Find-in-document (⌘F)
- [ ] Find-and-replace
- [ ] Search result highlighting
- [ ] Full-text search across project

### Track B: Writing Targets UI
- [ ] Document word count targets
- [ ] Project targets
- [ ] Session targets
- [ ] Progress indicators in sidebar

---

## Sprint 6: Core UI Features (Mar - Apr)

### Track A: Split Editor
- [ ] Horizontal + vertical split views
- [ ] Drag-to-resize divider
- [ ] Independent scrolling
- [ ] Platform-specific optimizations

### Track B: Composition Mode
- [ ] Fullscreen distraction-free mode
- [ ] Customizable background
- [ ] Fade-in controls on hover
- [ ] Keyboard toggle (⌘⇧F)

### Track C: Snapshots
- [ ] Snapshot storage format
- [ ] Auto-snapshot on significant changes
- [ ] Manual snapshot command
- [ ] Snapshot browser + restore

---

## Sprint 7: Organization + Sync (Apr - May)

### Track A: Labels & Status UI
- [ ] Label model UI (name, color)
- [ ] Status model UI (To Do → Done)
- [ ] Binder color indicators
- [ ] Batch operations

### Track B: Cork Board
- [ ] Card component design
- [ ] Grid layout with drag-and-drop
- [ ] Card size options
- [ ] Keyboard navigation

### Track C: Outliner
- [ ] Table view implementation
- [ ] Sortable columns
- [ ] Inline editing
- [ ] Column customization

### Track D: CloudKit Sync
- [ ] CloudKit container setup
- [ ] CKRecord mapping
- [ ] Conflict resolution (last-write-wins initially)
- [ ] Sync status indicators
- [ ] Offline/online handling

---

## Sprint 8: Export + Polish (May - Jun)

### Multi-Format Export
- [ ] Compile/export UI improvements
- [ ] DOCX export
- [ ] EPUB export
- [ ] HTML export
- [ ] PDF improvements
- [ ] LaTeX export
- [ ] Export templates/presets

### Polish Sprint
- [ ] Bug fixes from beta feedback
- [ ] Performance optimization
- [ ] Accessibility audit

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
Find & Replace             🔜 Next
Writing Targets UI         🔜 Next
Split Editor               🔜 Planned
Composition Mode           🔜 Planned
Cork Board                 🔜 Planned
Outliner                   🔜 Planned
CloudKit Sync              🔜 Planned
Export Formats             🔜 Planned
```

---

## Upcoming Milestones

| Target | Deliverable |
|--------|-------------|
| Feb 2026 | Find & replace, writing targets UI |
| Mar 2026 | Split editor working |
| Apr 2026 | Composition mode, snapshots |
| May 2026 | CloudKit sync, organization views |
| Jun 2026 | **v1.0 Launch**: Feature parity achieved |

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

1. [ ] Implement find & replace (⌘F)
2. [ ] Add writing targets UI
3. [ ] Plan split editor architecture
4. [ ] Test Scrivener import with more real-world projects
5. [ ] Recruit beta testers for upcoming release

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
