# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Manuscript is an open-source, native writing application for iOS and macOS, designed as an alternative to Scrivener and Ulysses. It prioritizes file ownership (Markdown-based), privacy (no required accounts), and optional AI integration.

**Current state**: Active development. The app is built as a multi-platform SwiftUI application with a single Xcode project supporting both iOS and macOS.

## Build & Development

### Requirements
- Xcode 15.0+
- Swift 5.9+
- iOS 17.0+ SDK / macOS 14.0+ (Sonoma) SDK

### Building
```bash
open Manuscript/Manuscript.xcodeproj
```
Select your target platform (iOS or macOS) from the Xcode scheme selector.
Build: ⌘+B | Run: ⌘+R

### Website (GitHub Pages)
The marketing site lives in `docs/` and uses Jekyll with custom HTML.
- Config: `docs/_config.yml`
- Main page: `docs/index.html`
- Published at: https://manuscriptapp.github.io/manuscript

## Architecture

### Project Structure
```
Manuscript/
├── Manuscript.xcodeproj     # Multi-platform Xcode project
├── Manuscript/              # Main app code
│   ├── Models/             # Data models
│   ├── ViewModels/         # View models (MVVM)
│   ├── Views/              # SwiftUI views
│   │   └── Platform/       # Platform-specific views (iOS/macOS)
│   └── Services/           # Business logic and services
├── ManuscriptTests/        # Unit tests
└── ManuscriptUITests/      # UI tests
```

### Design Principles
- **SwiftUI** for all UI components
- **MVVM pattern** where applicable
- **Multi-platform** single codebase with `#if os(macOS)` / `#if os(iOS)` conditional compilation
- Platform-specific UI in `Views/Platform/`; shared logic elsewhere
- Standard Markdown as the primary file format

## Key Documentation

- `meta/FEATURE_PARITY.md` - Feature matrix comparing Manuscript vs Scrivener vs Ulysses
- `CONTRIBUTING.md` - Development setup and PR process
- `LICENSE` - MPL-2.0

## Folder Structure

```
Manuscript/     # Multi-platform app (iOS and macOS)
docs/           # Marketing website (GitHub Pages)
meta/           # Internal docs, feature parity, planning
```

## Code Style

Follow Swift API Design Guidelines. Test on both iOS and macOS when possible.
