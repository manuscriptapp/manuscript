# Manuscript

Free, open-source writing app for iOS and macOS.

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-blue.svg)](https://github.com/manuscriptapp/manuscript)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)

## What is this?

A native SwiftUI writing app with:

- **Free forever** — No purchase, no subscription, no in-app purchases
- **Open source** — MPL-2.0 licensed, full source code available
- **iCloud sync** — CloudKit sync across all Apple devices, no account required
- **On-device AI** — Apple Foundation Models integration, plus bring-your-own API keys
- **Standard files** — Markdown-based format, portable and future-proof

Think Scrivener or Ulysses, but free and open source.

## Features

| Feature | Description |
|---------|-------------|
| Project organization | Binder sidebar with chapters, scenes, notes, research |
| Markdown editing | Standard Markdown files |
| Snapshots | Automatic version history |
| Split editor | View two documents side by side |
| Composition mode | Distraction-free fullscreen |
| Export | PDF, DOCX, EPUB, HTML, LaTeX, Fountain |
| CloudKit sync | Free sync across iOS and macOS |
| AI assistance | Apple Foundation Models + custom API keys |

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+ (to build from source)

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
| Free cloud sync | CloudKit | No | No |
| On-device AI | Yes | No | Paid |

## Roadmap

**Phase 1: Foundation**
- [ ] Core Markdown editor
- [ ] Project binder
- [ ] macOS app

**Phase 2: Core**
- [ ] iOS app
- [ ] Split editor
- [ ] Snapshots
- [ ] Composition mode

**Phase 3: Organization**
- [ ] Cork board
- [ ] Outliner
- [ ] Labels and status
- [ ] Search

**Phase 4: Sync & Export**
- [ ] CloudKit sync
- [ ] Compile/export
- [ ] Import from Scrivener

**Phase 5: Advanced**
- [ ] Research folder
- [ ] Writing statistics
- [ ] Apple Foundation Models
- [ ] Custom AI APIs

## Contributing

Issues and PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MPL-2.0](LICENSE)

---

[Website](https://manuscriptapp.github.io/manuscript) · [Issues](https://github.com/manuscriptapp/manuscript/issues) · [Discussions](https://github.com/manuscriptapp/manuscript/discussions)
