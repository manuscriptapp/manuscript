# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Manuscript is an open-source, native writing application for iOS and macOS, designed as an alternative to Scrivener and Ulysses. It prioritizes file ownership (Markdown-based), privacy (no required accounts), and optional AI integration.

**Current state**: Early-stage project with documentation and marketing website. The iOS/, macOS/, and Shared/ source directories are planned but not yet created.

## Build & Development

### Requirements
- Xcode 15.0+
- Swift 5.9+
- iOS 17.0+ SDK / macOS 14.0+ (Sonoma) SDK

### Building (when source exists)
```bash
open iOS/Manuscript.xcodeproj   # For iOS
open macOS/Manuscript.xcodeproj # For macOS
```
Build: ⌘+B | Run: ⌘+R

### Website (GitHub Pages)
The marketing site lives in `docs/` and uses Jekyll with custom HTML.
- Config: `docs/_config.yml`
- Main page: `docs/index.html`
- Published at: https://manuscriptapp.github.io/manuscript

## Architecture

### Planned Structure
```
iOS/          # iOS-specific code and Xcode project
macOS/        # macOS-specific code and Xcode project
Shared/       # Cross-platform shared code
```

### Design Principles
- **SwiftUI** for all UI components
- **MVVM pattern** where applicable
- Platform-specific code in respective folders; shared logic in `Shared/`
- Standard Markdown as the primary file format

## Key Documentation

- `meta/FEATURE_PARITY.md` - Feature matrix comparing Manuscript vs Scrivener vs Ulysses
- `CONTRIBUTING.md` - Development setup and PR process
- `LICENSE` - MPL-2.0

## Folder Structure

```
docs/           # Marketing website (GitHub Pages)
meta/           # Internal docs, feature parity, planning
iOS/            # iOS app (planned)
macOS/          # macOS app (planned)
Shared/         # Cross-platform code (planned)
```

## Code Style

Follow Swift API Design Guidelines. Test on both iOS and macOS when possible.
