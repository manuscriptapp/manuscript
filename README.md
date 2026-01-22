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
| Inline renaming | ✅ | Scrivener-style click-to-rename in sidebar |
| Document customization | ✅ | Custom icons (20+) and colors for folders and documents |
| Characters & Locations | ✅ | World-building with character/location tracking |
| Writing statistics | ✅ | Word counts, daily history, streaks, session tracking |
| Comments system | ✅ | Inline comments with chat bubble UI and inspector |
| Templates | ✅ | Hero's Journey and other project templates |
| Scrivener import | ✅ | Full .scriv import with RTF conversion and comments |
| Export | ✅ | PDF and Markdown export |
| AI assistance | ✅ | Text generation with custom API keys (OpenAI, Anthropic) |
| State restoration | ✅ | Remembers last open document and expanded folders |
| Paragraph formatting | ✅ | First-line indentation, line spacing |
| Find & replace | 🔜 | Search and replace within documents |
| Snapshots | 🔜 | Version history (infrastructure ready) |
| iCloud Drive sync | ✅ | Sync across devices via iCloud Drive |
| More export formats | 🔜 | DOCX, EPUB, HTML, LaTeX |

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

Projects are folders with Markdown and JSON. Human-readable, Git-friendly.

```
MyNovel.manuscript/
├── project.json
├── contents/
│   ├── draft/
│   │   ├── 01-chapter-one.md
│   │   └── 02-chapter-two.md
│   ├── notes/
│   └── research/
├── snapshots/
└── assets/
```

## Comparison

| | Manuscript | Scrivener | Ulysses |
|---|---|---|---|
| Price | Free | $49+ | $50/year |
| Open source | Yes | No | No |
| Native app | SwiftUI | AppKit | AppKit |
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
- [x] Project templates (Hero's Journey)

**Phase 3: World-Building** ✅
- [x] Character management
- [x] Location tracking
- [x] Document-to-character/location linking

**Phase 4: Import & Export** ✅
- [x] Scrivener .scriv import (with RTF conversion, comments, icons)
- [x] PDF export
- [x] Markdown export

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
- [x] Inline document renaming

**Phase 7: Advanced** (In Progress)
- [ ] Find & replace
- [ ] Writing targets UI
- [ ] Split editor (side-by-side documents)
- [ ] Composition mode (distraction-free)
- [ ] Cork board view
- [ ] Outliner view
- [x] iCloud Drive sync
- [ ] DOCX, EPUB, HTML, LaTeX export
- [ ] Version comparison for snapshots

## Contributing

Issues and PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MPL-2.0](LICENSE)

---

[Website](https://manuscriptapp.github.io/manuscript) · [Issues](https://github.com/manuscriptapp/manuscript/issues) · [Discussions](https://github.com/manuscriptapp/manuscript/discussions)
