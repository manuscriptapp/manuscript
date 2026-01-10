# Feature Parity

This document tracks Manuscript's feature parity with [Scrivener 3](https://www.literatureandlatte.com/scrivener/overview) and [Ulysses](https://ulysses.app/), the leading long-form writing applications for Apple platforms. Our goal is to provide a Scrivener/Ulysses-like experience that is fully open-source, free to use, and without vendor lock-in.

**Legend:**
- ✅ Implemented
- 🔜 Planned
- ❌ Not Planned
- ➖ Not Applicable

---

## Overview

| Aspect | Scrivener | Ulysses | Manuscript |
|--------|-----------|---------|------------|
| **Price** | $49-59 (one-time) | $50/year (subscription) | Free |
| **License** | Proprietary | Proprietary | MPL-2.0 (Open Source) |
| **Platforms** | macOS, Windows, iOS | macOS, iOS | macOS, iOS |
| **File Format** | Proprietary (.scriv) | Proprietary (library-based) | Standard (Markdown) |
| **Sync** | Dropbox (manual) | iCloud (built-in) | Free CloudKit sync |
| **AI Features** | None | Paid add-on | Built-in (optional) |

---

## Core Writing Features

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Rich Text Editor** | ✅ | 🔜 | Manuscript focuses on Markdown |
| **Markdown Support** | Partial | ✅ | Native Markdown in Manuscript |
| **Distraction-Free Mode** | ✅ | 🔜 | Full-screen composition mode |
| **Split Editor** | ✅ | 🔜 | View two documents side-by-side |
| **Copyholders** | ✅ | 🔜 | View 3-4 documents at once |
| **Typewriter Scrolling** | ✅ | 🔜 | Keep current line centered |
| **Auto-Save** | ✅ | ✅ | Continuous saving |
| **Undo/Redo** | ✅ | ✅ | Full undo history |
| **Find & Replace** | ✅ | 🔜 | Project-wide search |
| **Spell Check** | ✅ | ✅ | System spell check |
| **Grammar Check** | ✅ | 🔜 | System grammar check |
| **Word Count (Live)** | ✅ | 🔜 | Real-time word count |
| **Character Count** | ✅ | 🔜 | Real-time character count |
| **Dark Mode** | ✅ | ✅ | System-aware theming |

---

## Project Organization

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Binder (Sidebar)** | ✅ | ✅ | Hierarchical document navigator |
| **Folders & Documents** | ✅ | ✅ | Nested organization |
| **Drag & Drop Reordering** | ✅ | 🔜 | Rearrange sections freely |
| **Document Icons** | ✅ | 🔜 | Custom icons per document |
| **Color Labels** | ✅ | 🔜 | Color-code documents |
| **Status Labels** | ✅ | 🔜 | Track draft status |
| **Document Templates** | ✅ | 🔜 | Character sheets, etc. |
| **Collections** | ✅ | 🔜 | Saved search results/groups |
| **Favorites/Bookmarks** | ✅ | 🔜 | Quick access to documents |
| **Trash Folder** | ✅ | 🔜 | Recoverable deleted items |

---

## Corkboard

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Index Card View** | ✅ | 🔜 | Visual card-based overview |
| **Card Synopses** | ✅ | 🔜 | Summary per document |
| **Card Colors** | ✅ | 🔜 | Color-coded cards |
| **Card Images** | ✅ | ❌ | Photos on cards |
| **Grid Corkboard** | ✅ | 🔜 | Aligned card layout |
| **Freeform Corkboard** | ✅ | ❌ | Free-position cards |
| **Corkboard Stacking** | ✅ | ❌ | Stacked card groups |
| **Commit Arrangement** | ✅ | ❌ | Apply freeform to binder |

---

## Outliner

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Outline View** | ✅ | 🔜 | Hierarchical list view |
| **Column Customization** | ✅ | 🔜 | Show/hide metadata columns |
| **Word Count Column** | ✅ | 🔜 | Per-section word counts |
| **Target Count Column** | ✅ | 🔜 | Target vs actual |
| **Synopsis Column** | ✅ | 🔜 | Document summaries |
| **Label Column** | ✅ | 🔜 | Status/label display |
| **Section Type Column** | ✅ | 🔜 | Document type display |
| **Custom Metadata** | ✅ | 🔜 | User-defined columns |
| **Sort by Column** | ✅ | 🔜 | Click-to-sort |
| **Expand/Collapse All** | ✅ | 🔜 | Quick view controls |

---

## Research & Reference

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Research Folder** | ✅ | ✅ | Dedicated research area |
| **Import Images** | ✅ | 🔜 | Store reference images |
| **Import PDFs** | ✅ | 🔜 | Store PDF documents |
| **Import Web Pages** | ✅ | 🔜 | Archive web content |
| **Import Audio/Video** | ✅ | ❌ | Media file storage |
| **Document Links** | ✅ | 🔜 | Link between documents |
| **External Links** | ✅ | 🔜 | Link to URLs/files |
| **Quick Reference Panels** | ✅ | 🔜 | Floating document windows |
| **Inline Annotations** | ✅ | 🔜 | In-text notes |
| **Comments** | ✅ | 🔜 | Margin comments |
| **Footnotes** | ✅ | 🔜 | Academic footnotes |
| **Endnotes** | ✅ | 🔜 | End-of-document notes |

---

## Snapshots & Version Control

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Manual Snapshots** | ✅ | ✅ | Save document versions |
| **Titled Snapshots** | ✅ | 🔜 | Name your snapshots |
| **Compare Snapshots** | ✅ | 🔜 | Diff between versions |
| **Rollback to Snapshot** | ✅ | ✅ | Restore previous version |
| **Auto-Snapshots on Sync** | ✅ | 🔜 | Automatic version backup |
| **Snapshot Manager** | ✅ | 🔜 | Browse all snapshots |

---

## Compile & Export

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Compile to Single Document** | ✅ | 🔜 | Merge all sections |
| **Export to Word (.docx)** | ✅ | 🔜 | Microsoft Word format |
| **Export to RTF** | ✅ | 🔜 | Rich Text Format |
| **Export to PDF** | ✅ | 🔜 | Print-ready PDF |
| **Export to ePub** | ✅ | 🔜 | eBook format |
| **Export to Kindle (mobi)** | ✅ | 🔜 | Amazon Kindle format |
| **Export to Final Draft** | ✅ | ❌ | Screenplay software |
| **Export to Plain Text** | ✅ | ✅ | Markdown/TXT export |
| **Export to HTML** | ✅ | 🔜 | Web format |
| **Export to OpenOffice** | ✅ | 🔜 | ODT format |
| **Export to LaTeX** | ✅ | 🔜 | Via Pandoc/MultiMarkdown |
| **Compile Presets** | ✅ | 🔜 | Saved export settings |
| **Section Layouts** | ✅ | 🔜 | Format sections differently |
| **Front/Back Matter** | ✅ | 🔜 | Title pages, etc. |
| **Table of Contents** | ✅ | 🔜 | Auto-generated TOC |
| **Page Numbering** | ✅ | 🔜 | Print formatting |
| **Headers/Footers** | ✅ | 🔜 | Running headers |
| **Image Handling** | ✅ | 🔜 | Resize/resample on export |
| **Replacements** | ✅ | 🔜 | Find/replace on compile |

---

## Scriptwriting

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Screenplay Mode** | ✅ | ❌ | Industry-standard formatting |
| **Stage Play Mode** | ✅ | ❌ | Theatre script format |
| **Comic Script Mode** | ✅ | ❌ | Comic book scripting |
| **Radio Drama Mode** | ✅ | ❌ | Audio drama format |
| **Auto-Element Formatting** | ✅ | ❌ | Auto-style scene headings |
| **Dialogue Focus** | ✅ | ❌ | Highlight only dialogue |
| **Script Notes** | ✅ | ❌ | Production notes |

---

## Writing Tools

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Name Generator** | ✅ | ❌ | Generate character names |
| **Writing Targets** | ✅ | 🔜 | Session/document goals |
| **Project Targets** | ✅ | 🔜 | Total manuscript goals |
| **Writing History** | ✅ | 🔜 | Track daily word counts |
| **Session Targets** | ✅ | 🔜 | Daily writing goals |
| **Deadline Tracking** | ✅ | 🔜 | Set completion dates |
| **Linguistic Focus** | ✅ | ❌ | Highlight word types (Mac) |
| **Text Statistics** | ✅ | 🔜 | Readability scores |
| **Keywords/Tags** | ✅ | 🔜 | Tag documents |

---

## Formatting & Styles

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Paragraph Styles** | ✅ | 🔜 | Reusable formatting |
| **Character Styles** | ✅ | 🔜 | Inline text styles |
| **Style Presets** | ✅ | 🔜 | Save style collections |
| **Block Quotes** | ✅ | ✅ | Via Markdown |
| **Lists (Bullet/Number)** | ✅ | ✅ | Via Markdown |
| **Tables** | ✅ | 🔜 | Markdown tables |
| **Images in Text** | ✅ | 🔜 | Inline images |
| **Font Customization** | ✅ | 🔜 | Per-editor fonts |
| **Line Spacing** | ✅ | 🔜 | Adjustable spacing |
| **Indentation** | ✅ | 🔜 | First-line indent |

---

## Project Templates

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Novel Template** | ✅ | 🔜 | Pre-configured novel project |
| **Short Story Template** | ✅ | 🔜 | Short fiction setup |
| **Non-Fiction Template** | ✅ | 🔜 | Research paper/book |
| **Screenplay Template** | ✅ | ❌ | Movie script setup |
| **Stage Play Template** | ✅ | ❌ | Theatre script setup |
| **Poetry Template** | ✅ | 🔜 | Poetry collection |
| **Essay Template** | ✅ | 🔜 | Academic essay |
| **Recipe Collection** | ✅ | ❌ | Cookbook template |
| **Custom Templates** | ✅ | 🔜 | User-created templates |
| **Template Chooser** | ✅ | 🔜 | New project dialog |

---

## Import Capabilities

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Import Word (.docx)** | ✅ | 🔜 | Microsoft Word files |
| **Import RTF** | ✅ | 🔜 | Rich Text files |
| **Import Plain Text** | ✅ | ✅ | TXT/Markdown files |
| **Import HTML** | ✅ | 🔜 | Web pages |
| **Import OPML** | ✅ | 🔜 | Outline files |
| **Import Final Draft** | ✅ | ❌ | Screenplay files |
| **Import & Split** | ✅ | 🔜 | Split by delimiter |
| **Import Folder of Files** | ✅ | 🔜 | Batch import |
| **Drag & Drop Import** | ✅ | 🔜 | Quick file import |

---

## Sync & Backup

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Cloud Sync** | Dropbox (manual) | ✅ CloudKit | Free, automatic sync |
| **iOS Sync** | ✅ | ✅ | Mobile sync |
| **Automatic Backups** | ✅ | 🔜 | Scheduled backups |
| **Backup on Close** | ✅ | 🔜 | Auto-backup on quit |
| **Backup to Folder** | ✅ | 🔜 | Custom backup location |
| **ZIP Backups** | ✅ | 🔜 | Compressed backups |
| **External Folder Sync** | ✅ | ❌ | Sync with plain text folder |

---

## User Interface

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **Customizable Toolbar** | ✅ | 🔜 | Add/remove buttons |
| **Keyboard Shortcuts** | ✅ | ✅ | System + custom shortcuts |
| **Full Screen Mode** | ✅ | ✅ | macOS native |
| **Composition Mode** | ✅ | 🔜 | Distraction-free writing |
| **Inspector Panel** | ✅ | 🔜 | Document metadata sidebar |
| **Multiple Windows** | ✅ | 🔜 | Open project in new window |
| **Tabs** | ✅ | 🔜 | macOS tab support |
| **Touch Bar Support** | ✅ | 🔜 | MacBook Pro Touch Bar |
| **Themes** | Limited | 🔜 | Custom color schemes |
| **Customizable Colors** | ✅ | 🔜 | Editor/background colors |

---

## AI & Smart Features

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **AI Writing Assistant** | ❌ | ✅ | Built-in AI support |
| **On-Device AI** | ❌ | ✅ | Apple Foundation Models |
| **Cloud AI (BYOK)** | ❌ | ✅ | OpenAI, Anthropic, etc. |
| **AI Suggestions** | ❌ | ✅ | Writing suggestions |
| **AI Rephrasing** | ❌ | ✅ | Rewrite assistance |
| **Per-Project AI Config** | ❌ | ✅ | Enable AI per project |
| **Privacy-First AI** | ❌ | ✅ | On-device processing |

---

## Platform & Technical

| Feature | Scrivener | Manuscript | Notes |
|---------|:---------:|:----------:|-------|
| **macOS Native** | ✅ | ✅ | Full macOS support |
| **iOS/iPadOS Native** | ✅ | ✅ | iPhone & iPad apps |
| **Windows Support** | ✅ | ❌ | Not planned (Apple-only) |
| **Linux Support** | ❌ | ❌ | Not available |
| **Apple Silicon Native** | ✅ | ✅ | M1/M2/M3 optimized |
| **SwiftUI** | ❌ | ✅ | Modern Apple framework |
| **iCloud Integration** | ❌ | ✅ | Native CloudKit sync |
| **Handoff Support** | ❌ | 🔜 | Continue on other device |
| **Siri Shortcuts** | ❌ | 🔜 | Automation support |
| **Stage Manager** | ❌ | 🔜 | iPadOS 16+ |
| **Widgets** | ❌ | 🔜 | Home screen widgets |

---

## Licensing & Philosophy

| Aspect | Scrivener | Manuscript |
|--------|-----------|------------|
| **Source Code** | Closed | Open (MPL-2.0) |
| **File Format** | Proprietary | Open (Markdown) |
| **Pricing** | Paid ($49+) | Free forever |
| **Data Ownership** | User owns files | User owns files |
| **Vendor Lock-in** | Moderate | None |
| **Community Input** | Limited | GitHub Issues/PRs |
| **Audit-able** | No | Yes |
| **Modifiable** | No | Yes |

---

## Summary Statistics

| Category | Total Features | Implemented | Planned | Not Planned |
|----------|:--------------:|:-----------:|:-------:|:-----------:|
| Core Writing | 14 | 5 | 9 | 0 |
| Project Organization | 10 | 2 | 8 | 0 |
| Corkboard | 8 | 0 | 4 | 4 |
| Outliner | 10 | 0 | 10 | 0 |
| Research & Reference | 12 | 1 | 10 | 1 |
| Snapshots | 6 | 2 | 4 | 0 |
| Compile & Export | 18 | 1 | 16 | 1 |
| Scriptwriting | 7 | 0 | 0 | 7 |
| Writing Tools | 9 | 0 | 7 | 2 |
| Formatting & Styles | 10 | 3 | 7 | 0 |
| Project Templates | 10 | 0 | 7 | 3 |
| Import Capabilities | 9 | 1 | 7 | 1 |
| Sync & Backup | 7 | 2 | 4 | 1 |
| User Interface | 11 | 2 | 9 | 0 |
| AI & Smart Features | 7 | 7 | 0 | 0 |
| Platform & Technical | 11 | 4 | 5 | 2 |
| **TOTAL** | **149** | **30 (20%)** | **107 (72%)** | **12 (8%)** |

---

## Features Unique to Manuscript

These features are available in Manuscript but **not** in Scrivener:

1. **Open Source** - Full source code transparency under MPL-2.0
2. **Free Forever** - No purchase required
3. **Built-in AI** - On-device and cloud AI integration
4. **Apple Foundation Models** - Free, private on-device AI
5. **Bring Your Own AI** - Use your own API keys
6. **Native CloudKit Sync** - Free, automatic sync across Apple devices
7. **Modern SwiftUI** - Built with Apple's latest UI framework
8. **Standard File Formats** - No proprietary lock-in
9. **Community-Driven Development** - GitHub-based contributions

---

## Intentionally Not Planned

These Scrivener features are intentionally not planned for Manuscript:

| Feature | Reason |
|---------|--------|
| Windows Support | Focus on native Apple experience |
| Scriptwriting Modes | Focus on prose writing; use dedicated tools |
| Freeform Corkboard | Complex feature with limited value |
| Name Generator | Third-party tools available |
| Final Draft Export | Screenplay features not in scope |
| Audio/Video Import | Storage bloat; link externally instead |
| Linguistic Focus | Scope creep; consider AI alternatives |

---

## Contributing

Want to help close the gap? Check out our [Contributing Guide](CONTRIBUTING.md) to get started. Priority areas:

1. **Corkboard View** - Visual index card interface
2. **Outliner View** - Hierarchical document view
3. **Compile System** - Multi-format export
4. **Writing Targets** - Word count goals

---

## Resources

- [Scrivener Overview](https://www.literatureandlatte.com/scrivener/overview)
- [Scrivener 3 Manual (PDF)](https://www.literatureandlatte.com/docs/Scrivener_Manual-Mac.pdf)
- [Ulysses](https://ulysses.app/)
- [Manuscript README](README.md)
- [Manuscript Contributing Guide](CONTRIBUTING.md)

---

*Last updated: January 2026*
