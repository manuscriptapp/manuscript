<div align="center">

# Manuscript

**Open-source long-form writing for iOS & macOS**

Own your files. Free CloudKit sync. Optional AI assistance.

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-blue.svg)](https://github.com/manuscriptapp/manuscript)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[Features](#features) · [Installation](#installation) · [Documentation](#documentation) · [Roadmap](#roadmap) · [Contributing](#contributing) · [License](#license)

</div>

---

## Overview

Manuscript is a **native, open-source writing app** designed for writers who want **full control over their files**. Built with SwiftUI for iOS and macOS, it supports project-based writing, Markdown editing, snapshots, and optional AI-assisted writing.

**Our goal**: Provide a Scrivener-like experience without lock-in—fully open-source and free to use.

## Features

### Core Writing Experience
- **Project-based writing** — Organize chapters, notes, and research in one place
- **Markdown support** — Flexible formatting with portable files
- **Snapshots & undo history** — Never lose your work with built-in version tracking
- **Cross-platform** — Native apps for iOS and macOS with shared architecture

### Sync & Storage
- **Files first** — Your writing is stored in standard, portable formats you own
- **Free CloudKit sync** — Keep projects synchronized across all your Apple devices
- **No account required** — Everything works offline; sync is optional

### AI Integration (Optional)
- **Apple Foundation Models** — Free, on-device AI for suggestions, rephrasing, and inspiration
- **Bring Your Own AI** — Use your own API keys (OpenAI, Anthropic, etc.)
- **Per-project configuration** — Enable AI features only where you want them

## Philosophy

| Principle | Description |
|-----------|-------------|
| **Files First** | Your writing belongs to you, not the cloud. Full file ownership always. |
| **Privacy First** | No accounts, no tracking. CloudKit sync is optional and encrypted. |
| **Open Source** | All code is visible, auditable, and modifiable under MPL-2.0. |
| **Community Driven** | Feedback and contributions shape the project's direction. |

## Installation

### Requirements

- **iOS**: iOS 17.0 or later
- **macOS**: macOS 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later (for building from source)

### Download

Coming soon to the App Store and TestFlight.

### Build from Source

```bash
# Clone the repository
git clone https://github.com/manuscriptapp/manuscript.git
cd manuscript

# Open in Xcode
open iOS/Manuscript.xcodeproj   # For iOS
open macOS/Manuscript.xcodeproj # For macOS
```

Build and run using Xcode's standard workflow (⌘+R).

## Documentation

### Project Structure

```
manuscript/
├── iOS/                    # iOS application
├── macOS/                  # macOS application
├── Shared/                 # Cross-platform shared code
├── Examples/               # Sample projects
├── Docs/                   # Additional documentation
└── website/                # GitHub Pages marketing site
```

## Roadmap

- [ ] Core editor with markdown support
- [ ] Project structure (chapters, scenes, notes)
- [ ] Snapshots and version history
- [ ] macOS app
- [ ] iOS app
- [ ] CloudKit sync
- [ ] Apple Foundation Models integration
- [ ] Custom API key support (OpenAI, Anthropic)
- [ ] Export to common formats (PDF, DOCX, EPUB, RTF, HTML, LaTeX, Fountain)
- [ ] Import from Scrivener and Word
- [ ] Export to Scrivener and Word

## Contributing

We welcome contributions of all kinds! Here's how you can help:

- **Report bugs** — Found an issue? [Open a bug report](https://github.com/manuscriptapp/manuscript/issues/new?template=bug_report.md)
- **Suggest features** — Have an idea? [Request a feature](https://github.com/manuscriptapp/manuscript/issues/new?template=feature_request.md)
- **Submit code** — Ready to code? Check out our [Contributing Guide](CONTRIBUTING.md)
- **Improve docs** — Help us make documentation clearer

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

## Security

Found a security vulnerability? Please report it responsibly. See our [Security Policy](SECURITY.md) for details on how to report security issues.

## Community

- **GitHub Issues** — [Report bugs and request features](https://github.com/manuscriptapp/manuscript/issues)
- **Discussions** — [Join the conversation](https://github.com/manuscriptapp/manuscript/discussions)
- **Website** — [manuscriptapp.github.io/manuscript](https://manuscriptapp.github.io/manuscript)

## License

Manuscript is licensed under the [Mozilla Public License 2.0](LICENSE).

```
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
```

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Inspired by the writing app community's desire for open, file-first tools
- Thanks to all [contributors](https://github.com/manuscriptapp/manuscript/graphs/contributors)

---

<div align="center">

Made with care for writers who value ownership and privacy.

**[Star this repo](https://github.com/manuscriptapp/manuscript)** to follow updates

</div>
