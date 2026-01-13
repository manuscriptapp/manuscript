# Manuscript Action Plan

*Last updated: January 2026*

This document outlines the prioritized next steps for Manuscript development. **Aggressive timeline targeting feature parity by June 2026.**

---

## Executive Summary

Manuscript has a solid SwiftUI foundation. We're compressing the roadmap to reach **feature parity with Scrivener by June 2026** - 6 months instead of 12.

**Aggressive Timeline:**
- **Week 1-2 (Jan 13-26)**: Foundation fixes + start rich text
- **Week 3-6 (Jan 27 - Feb 23)**: Rich text complete + Scrivener import
- **Week 7-10 (Feb 24 - Mar 23)**: Core UI features (parallel tracks)
- **Week 11-14 (Mar 24 - Apr 20)**: Organization + CloudKit sync
- **Week 15-18 (Apr 21 - May 18)**: Export formats + polish
- **Week 19-22 (May 19 - Jun 15)**: Advanced features + beta release

**Key Strategy**: Run multiple tracks in parallel. Ship incrementally.

---

## Sprint 1: Foundation Blitz (Week 1 - Jan 13-19)

**Goal**: Fix all architectural debt in ONE week.

### Day 1-2: DocumentGroup Architecture
- [ ] Convert `ManuscriptDocument` from class to struct
- [ ] Fix `@Binding` with proper value-type semantics
- [ ] Update `FileDocument` implementation

### Day 3: Manager Consolidation
- [ ] Merge `DocumentManager` + `ManuscriptViewModel` into single manager
- [ ] Remove all duplicate state

### Day 4: API Updates
- [ ] Fix all deprecated `onChange` calls
- [ ] Update iCloud container ID to "manuscript"
- [ ] Remove all compiler warnings

### Day 5: Tests + Validation
- [ ] Unit tests for document save/load
- [ ] Test on iOS Simulator + macOS
- [ ] Set up CI pipeline

---

## Sprint 2: Rich Text MVP (Week 2 - Jan 20-26)

**Goal**: Basic formatting working. Ship it.

### Day 1-3: Core Implementation
- [ ] `AttributedString` + `TextEditor` integration
- [ ] Bold (⌘B), Italic (⌘I), Underline (⌘U)
- [ ] Keyboard shortcuts on both platforms

### Day 4-5: Toolbar + Polish
- [ ] Formatting toolbar component
- [ ] Integration with existing editor
- [ ] Basic Markdown ↔ AttributedString conversion

---

## Sprint 3: Rich Text Complete + Scrivener Import Start (Week 3-4 - Jan 27 - Feb 9)

**Run in parallel**: Two developers or alternating focus.

### Track A: Extended Formatting (Week 3)
- [ ] Font family selection
- [ ] Font size controls
- [ ] Text/highlight color pickers
- [ ] Full Markdown round-trip fidelity

### Track B: Scrivener Parser (Week 3-4)
- [ ] `.scriv` bundle parser
- [ ] `project.scrivx` XML parsing
- [ ] Binder hierarchy extraction
- [ ] RTF → Markdown converter (core formatting)

---

## Sprint 4: Scrivener Import Complete (Week 5-6 - Feb 10-23)

### Week 5: Content Conversion
- [ ] Complete RTF conversion (lists, headers, etc.)
- [ ] Metadata preservation (synopsis, notes, labels)
- [ ] Handle edge cases and malformed files

### Week 6: Integration + Ship
- [ ] Import UI (file picker, progress indicator)
- [ ] Import report showing conversion results
- [ ] Comprehensive test suite with real .scriv files
- [ ] **Ship v0.2 with rich text + Scrivener import**

---

## Sprint 5-6: Core UI Features (Week 7-10 - Feb 24 - Mar 23)

**Run ALL tracks in parallel.**

### Track A: Split Editor (Week 7-8)
- [ ] Horizontal + vertical split views
- [ ] Drag-to-resize divider
- [ ] Independent scrolling
- [ ] Platform-specific optimizations

### Track B: Search (Week 7-8)
- [ ] Full-text search across project
- [ ] Find-in-document (⌘F)
- [ ] Find-and-replace
- [ ] Search result highlighting

### Track C: Composition Mode (Week 9)
- [ ] Fullscreen distraction-free mode
- [ ] Customizable background
- [ ] Fade-in controls on hover
- [ ] Keyboard toggle (⌘⇧F)

### Track D: Snapshots (Week 9-10)
- [ ] Snapshot storage format
- [ ] Auto-snapshot on significant changes
- [ ] Manual snapshot command
- [ ] Snapshot browser + restore
- [ ] **Ship v0.3 with core UI features**

---

## Sprint 7-8: Organization + Sync (Week 11-14 - Mar 24 - Apr 20)

### Track A: Labels & Status (Week 11)
- [ ] Label model (name, color)
- [ ] Status model (To Do → Done)
- [ ] Binder color indicators
- [ ] Batch operations

### Track B: Cork Board (Week 11-12)
- [ ] Card component design
- [ ] Grid layout with drag-and-drop
- [ ] Card size options
- [ ] Keyboard navigation

### Track C: Outliner (Week 12-13)
- [ ] Table view implementation
- [ ] Sortable columns
- [ ] Inline editing
- [ ] Column customization

### Track D: CloudKit Sync (Week 11-14)
- [ ] CloudKit container setup
- [ ] CKRecord mapping
- [ ] Conflict resolution (last-write-wins initially)
- [ ] Sync status indicators
- [ ] Offline/online handling
- [ ] **Ship v0.4 with organization + sync**

---

## Sprint 9-10: Export + Polish (Week 15-18 - Apr 21 - May 18)

### Week 15-16: Multi-Format Export
- [ ] Compile/export UI
- [ ] DOCX export
- [ ] EPUB export
- [ ] HTML export
- [ ] PDF improvements

### Week 17: Additional Formats
- [ ] LaTeX export
- [ ] Fountain export (screenwriters)
- [ ] Export templates/presets

### Week 18: Polish Sprint
- [ ] Bug fixes from beta feedback
- [ ] Performance optimization
- [ ] Accessibility audit
- [ ] **Ship v0.5 with full export**

---

## Sprint 11-12: Advanced Features + Launch (Week 19-22 - May 19 - Jun 15)

### Week 19-20: AI Integration
- [ ] Apple Foundation Models integration
- [ ] Writing suggestions
- [ ] Grammar/style checking
- [ ] BYOK API key support

### Week 21: Research Folder + Stats
- [ ] Research item model
- [ ] File import for research
- [ ] Writing statistics tracking
- [ ] Word count goals

### Week 22: Launch Prep
- [ ] Final bug bash
- [ ] App Store screenshots + metadata
- [ ] Marketing site update
- [ ] **Launch v1.0**

---

## Parallel Execution Strategy

```
Week    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22
        |----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
Found.  ████
Rich    ░░░░████████████
Scriv        ░░░░░░░░████████████
Split                            ████████
Search                           ████████
Compose                                  ████
Snaps                                    ████████
Labels                                           ████
Cork                                             ████████
Outline                                              ████████
Sync                                             ████████████████
Export                                                           ████████████████
AI                                                                               ████████
Research                                                                                 ████
Launch                                                                                       ████
```

---

## Weekly Milestones

| Week | Date | Deliverable |
|------|------|-------------|
| 1 | Jan 19 | Foundation fixes complete, CI running |
| 2 | Jan 26 | Rich text MVP (bold/italic/underline) |
| 4 | Feb 9 | Scrivener parser working |
| 6 | Feb 23 | **v0.2 Release**: Rich text + Scrivener import |
| 8 | Mar 9 | Split editor + search working |
| 10 | Mar 23 | **v0.3 Release**: Core UI complete |
| 14 | Apr 20 | **v0.4 Release**: Organization + CloudKit sync |
| 18 | May 18 | **v0.5 Release**: Full export suite |
| 22 | Jun 15 | **v1.0 Launch**: Feature parity achieved |

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

## Immediate Actions (Today)

1. [ ] Start Sprint 1 - fix `ManuscriptDocument` struct conversion
2. [ ] Set up CI pipeline (GitHub Actions)
3. [ ] Create Sprint 1 branch
4. [ ] Block calendar for focused development
5. [ ] Recruit beta testers for Feb 23 release

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
