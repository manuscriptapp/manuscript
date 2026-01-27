# Manuscript

Free, open-source writing app for iOS and macOS.

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-blue.svg)](https://github.com/manuscriptapp/manuscript)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)

## What is this?

A native SwiftUI writing app with:

- **Free forever** — No purchase, no subscription
- **Open source** — MPL-2.0 licensed, full source code available
- **Standard files** — Markdown-based format, portable and future-proof
- **AI assistance** — Bring-your-own API keys for text generation
- **Scrivener import** — Migrate your existing projects with full history

Think Scrivener or Ulysses, but free and open source.

## Features

| Feature | Status | Description |
|---------|--------|-------------|
| Project organization | ✅ | Binder sidebar with folders and documents |
| Rich text editing | ✅ | Bold, italic, underline, fonts, sizes, colors, highlighting |
| Formatting toolbar | ✅ | Compact toolbar with font, size, color, and style controls |
| Drag & drop reorder | ✅ | Reorder and move documents/folders between locations |
| Document customization | ✅ | Custom icons (20+) and colors for folders and documents |
| Characters | ✅ | Character profiles with appearance, personality, and document linking |
| Locations | ✅ | Interactive maps with search, Look Around (Street View), and coordinates |
| Writing statistics | ✅ | Word counts, daily history, streaks, session tracking |
| Writing targets | ✅ | Word count goals for draft and daily sessions |
| Comments system | ✅ | Inline comments with chat bubble UI and inspector |
| Templates | ✅ | 9 story structure templates (Hero's Journey, Save the Cat, Three-Act, etc.) |
| Scrivener import | ✅ | Full .scriv import with RTF conversion and comments |
| Export | ✅ | PDF, Word, EPUB, Markdown, Plain Text, Scrivener |
| AI assistance | ✅ | Text generation with custom API keys (OpenAI, Anthropic) |
| State restoration | ✅ | Remembers last open document and expanded folders |
| Paragraph formatting | ✅ | First-line indentation, line spacing |
| Find & replace | ✅ | Search, highlight matches, navigate, replace single/all |
| iCloud Drive sync | ✅ | Sync across devices via iCloud Drive |
| Snapshots | ✅ | Version history with manual and auto snapshots |
| Corkboard view | ✅ | Index card view for visual organization |
| Split editor | ✅ | View two documents side-by-side (macOS) |
| Read mode | ✅ | Distraction-free reading with prose typography |
| Outliner view | ✅ | Hierarchical outline with sortable metadata columns |
| Composition mode | 🔜 | Distraction-free full-screen writing |
| Compile presets | 🔜 | Save and reuse export configurations |
| Print | 🔜 | Print documents directly |
| Import documents | 🔜 | Import Word, PDF, HTML files |
| Import images | 🔜 | Import and embed images in research |
| Auto backups | 🔜 | Automatic backup on close |
| Trash folder | ✅ | Soft-delete with restore capability |
| Document links | 🔜 | Internal links between documents |
| Keywords/tags | 🔜 | Tagging system for organization |
| Collections | 🔜 | Saved searches and filtered views |

## Requirements

- iOS 26.0+ / macOS 15.0+
- Xcode 16.0+ (to build from source)

## Build

```bash
git clone https://github.com/manuscriptapp/manuscript.git
cd manuscript
open Manuscript/Manuscript.xcodeproj
```

The project is a multi-platform SwiftUI app that supports both iOS and macOS from a single codebase. Select your target platform (iOS or macOS) from the Xcode scheme selector, then build and run with ⌘R.

## File Format

Projects are standard folders with Markdown and JSON files. Human-readable, Git-friendly, no lock-in.

```
MyNovel.manuscript/
├── project.json              # Project metadata, settings, characters, locations
├── state.json                # UI state (selected document, expanded folders)
├── contents/
│   ├── draft/
│   │   ├── folder.json       # Folder metadata and document ordering
│   │   ├── 01-chapter-one.md
│   │   ├── 01-chapter-one.notes.md      # Document notes (separate file)
│   │   ├── 01-chapter-one.comments.json # Inline comments
│   │   └── 02-chapter-two.md
│   ├── notes/
│   └── research/
├── trash/                    # Recoverable deleted items
├── snapshots/                # Version history by document
│   └── {document-id}/
│       ├── {snapshot-id}.json      # Snapshot metadata
│       └── {snapshot-id}.content   # Full document content at snapshot time
└── assets/                   # Media files (images, PDFs)
```

**Key files:**

- **project.json** — Title, author, genre, characters, locations, labels, statuses, writing history, compile settings
- **folder.json** — Document order, custom icons/colors, synopsis, keywords, labels
- **\*.md** — Document content in Markdown with optional YAML frontmatter for synopsis
- **\*.notes.md** — Document notes stored separately from content
- **\*.comments.json** — Inline comments with text ranges and timestamps

**Snapshots:**

Snapshots provide version history for each document. They can be created manually or automatically before major changes.

```json
// snapshots/{document-id}/{snapshot-id}.json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Before restructure",
  "creationDate": "2024-01-15T10:30:00Z",
  "wordCount": 2547
}
```

The corresponding `.content` file stores the full document text at the time of the snapshot. Snapshots can be viewed, restored, or deleted from the inspector's Snapshots tab.

Documents support YAML frontmatter:

```markdown
---
title: Chapter One
synopsis: The hero begins their journey
---

It was a dark and stormy night...
```

## Comparison

| | Manuscript | Scrivener | Ulysses |
|---|---|---|---|
| Price | Free | $49+ | $50/year |
| Open source | Yes | No | No |
| File format | Markdown | Proprietary | Markdown |
| Scrivener import | Yes | — | No |
| AI assistance | BYOK | No | Paid |

## Roadmap

**Phase 1: Foundation** ✅
- [x] Core Markdown editor
- [x] Project binder with sidebar
- [x] macOS app
- [x] iOS app

**Phase 2: Writing Experience** ✅
- [x] Document and folder customization (icons, colors)
- [x] Writing statistics and history tracking
- [x] Project templates (9 story structures)

**Phase 3: World-Building** ✅
- [x] Character management with profiles
- [x] Location tracking with interactive maps
- [x] Map search and Look Around (Street View)
- [x] Document-to-character/location linking

**Phase 4: Import & Export** ✅
- [x] Scrivener .scriv import (with RTF conversion, comments, icons)
- [x] PDF export with customizable fonts, margins, page sizes
- [x] Word (DOCX) export
- [x] EPUB export
- [x] Markdown export with optional frontmatter
- [x] Plain text export
- [x] Scrivener (.scriv) export

**Phase 5: AI Integration** ✅
- [x] AI text generation service
- [x] Custom API key support (OpenAI, Anthropic)
- [x] Chapter generation and rewriting assistance

**Phase 6: Rich Text & Polish** ✅
- [x] Rich text formatting (bold, italic, underline, fonts, colors)
- [x] Formatting toolbar with undo/redo
- [x] Paragraph first-line indentation
- [x] Line spacing control
- [x] Highlight/background color support
- [x] Comments system with inline highlighting
- [x] State restoration (last document, expanded folders)
- [x] Drag & drop reorder in sidebar
- [x] Move documents/folders between locations

**Phase 7: Advanced** (In Progress)
- [x] Find & replace
- [x] Snapshots (version history)
- [x] Corkboard view
- [x] iCloud Drive sync
- [x] Writing targets (draft and session goals)
- [x] Split editor (side-by-side documents on macOS)
- [x] Outliner view with sortable columns
- [x] Read mode (distraction-free reading)
- [x] Exclude files from compile (per-document include/exclude)
- [x] Trash folder (soft-delete with restore)
- [ ] Composition mode (distraction-free writing)
- [ ] Print documents
- [ ] Import documents (Word, PDF, HTML)
- [ ] Import images
- [ ] Auto backups
- [ ] Snapshot comparison/diff view

## Contributing

Issues and PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MPL-2.0](LICENSE)

---

[Website](https://manuscriptapp.github.io/manuscript) · [Issues](https://github.com/manuscriptapp/manuscript/issues) · [Discussions](https://github.com/manuscriptapp/manuscript/discussions)
