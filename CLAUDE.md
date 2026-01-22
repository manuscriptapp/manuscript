# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Metadata

| Property | Value |
|----------|-------|
| **Platform** | iOS 17.0+ / macOS 14.0+ (Sonoma) |
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI |
| **Architecture** | MVVM |
| **Package Management** | Swift Package Manager |
| **License** | MPL-2.0 |

## Project Overview

Manuscript is an open-source, native writing application for iOS and macOS, designed as an alternative to Scrivener and Ulysses. It prioritizes file ownership (Markdown-based), privacy (no required accounts), and optional AI integration.

**Current state**: Active development. The app is built as a multi-platform SwiftUI application with a single Xcode project supporting both iOS and macOS.

## Build & Development

### Requirements
- Xcode 15.0+
- Swift 5.9+
- iOS 17.0+ SDK / macOS 14.0+ (Sonoma) SDK

### Building with XcodeBuildMCP

This project uses XcodeBuildMCP for building. Set session defaults first:

```
mcp__XcodeBuildMCP__session-set-defaults:
  projectPath: /home/user/manuscript/Manuscript/Manuscript.xcodeproj
  scheme: manuscript
  simulatorName: iPhone 16 Pro
  useLatestOS: true
```

**Note:** The scheme name is lowercase `manuscript` (not `Manuscript`).

**Build Commands:**

| Command | Description |
|---------|-------------|
| `mcp__XcodeBuildMCP__build_macos` | Build for macOS |
| `mcp__XcodeBuildMCP__build_sim` | Build for iOS Simulator |
| `mcp__XcodeBuildMCP__build_run_macos` | Build and run on macOS |
| `mcp__XcodeBuildMCP__build_run_sim` | Build and run on iOS Simulator |
| `mcp__XcodeBuildMCP__test_macos` | Run tests on macOS |
| `mcp__XcodeBuildMCP__test_sim` | Run tests on iOS Simulator |
| `mcp__XcodeBuildMCP__list_schemes` | List available schemes |
| `mcp__XcodeBuildMCP__list_sims` | List available simulators |
| `mcp__XcodeBuildMCP__clean` | Clean build products |

**Simulator Interaction:**

| Command | Description |
|---------|-------------|
| `mcp__XcodeBuildMCP__screenshot` | Capture simulator screenshot |
| `mcp__XcodeBuildMCP__describe_ui` | Get view hierarchy with coordinates |
| `mcp__XcodeBuildMCP__tap` | Tap at coordinates or by accessibility ID |
| `mcp__XcodeBuildMCP__type_text` | Type text in focused field |
| `mcp__XcodeBuildMCP__gesture` | Perform gestures (scroll, swipe) |

### Building Manually
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

### Directory Structure
```
Manuscript/
├── Manuscript.xcodeproj        # Multi-platform Xcode project
├── Manuscript/                 # Main app code
│   ├── Models/                # Data models (structs, enums)
│   ├── ViewModels/            # View models (MVVM)
│   ├── Views/                 # SwiftUI views
│   │   ├── Components/        # Reusable UI components
│   │   │   ├── Book/         # Book-related components
│   │   │   ├── Character/    # Character components
│   │   │   ├── Common/       # Shared components
│   │   │   ├── Content/      # Content display components
│   │   │   ├── Document/     # Document components
│   │   │   ├── Location/     # Location components
│   │   │   ├── Sheets/       # Sheet/modal components
│   │   │   ├── Tabs/         # Tab components
│   │   │   └── Templates/    # Template components
│   │   ├── Import/           # Import-related views
│   │   ├── Book/             # Book views
│   │   └── Platform/         # Platform-specific views (iOS/macOS)
│   ├── Services/              # Business logic and services
│   │   └── Import/           # Import services (Scrivener, etc.)
│   └── Extensions/            # Swift extensions
├── ManuscriptTests/           # Unit tests
└── ManuscriptUITests/         # UI tests
```

### Design Principles
- **SwiftUI** for all UI components
- **MVVM pattern** for separation of concerns
- **Multi-platform** single codebase with `#if os(macOS)` / `#if os(iOS)` conditional compilation
- Platform-specific UI in `Views/Platform/`; shared logic elsewhere
- Standard Markdown as the primary file format

## Coding Standards

### Swift Best Practices
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use `async/await` for asynchronous operations
- Implement early exits with `guard` statements
- Prefer value types (structs) over reference types when possible
- Use meaningful, descriptive names for variables and functions
- Keep functions focused and single-purpose

### SwiftUI Conventions
- Extract views exceeding ~100 lines into smaller components
- Use `@State` for view-local state only
- Use `@Binding` for two-way data flow to child views
- Use `@Environment` for dependency injection
- Use `@Observable` (iOS 17+) for observable objects where applicable
- Prefer `NavigationStack` over deprecated `NavigationView`
- Place platform-specific code in `Views/Platform/`

### Multi-Platform Development
- Use `#if os(macOS)` / `#if os(iOS)` for platform-specific code
- Test changes on both iOS and macOS when possible
- Keep platform-specific views in `Views/Platform/`
- Share business logic across platforms

## Error Handling

- Use typed errors conforming to `LocalizedError` for user-facing errors
- Provide meaningful error messages
- Handle errors gracefully with appropriate UI feedback
- Log errors for debugging purposes

## Testing Requirements

- Write unit tests for ViewModels and business logic
- Place tests in `ManuscriptTests/`
- UI tests go in `ManuscriptUITests/`
- Test on both iOS and macOS when possible

## Constraints and Prohibitions

**Avoid:**
- Deprecated APIs when modern SwiftUI alternatives exist
- Monolithic views (extract into smaller components)
- Force unwrapping (`!`) without clear justification
- Blocking the main thread with synchronous operations
- Hard-coded strings for user-facing text (use localization)
- UIKit/AppKit unless absolutely necessary

**Do Not:**
- Skip UI tests during scaffolding phases (add later)
- Ignore compiler warnings
- Commit code with TODO comments for critical functionality

## Key Documentation

| Document | Description |
|----------|-------------|
| `meta/FEATURE_PARITY.md` | Feature matrix: Manuscript vs Scrivener vs Ulysses |
| `meta/PRE_LAUNCH_CHECKLIST.md` | Pre-launch requirements |
| `meta/SOFT_LAUNCH_PLAN.md` | Soft launch strategy |
| `meta/SCRIVENER_IMPORT_PLAN.md` | Scrivener import implementation |
| `CONTRIBUTING.md` | Development setup and PR process |
| `docs/file-format.md` | Manuscript file format specification |

## Planning Workflow

When implementing new features:

1. **Review existing docs** - Check `meta/` for relevant planning documents
2. **Understand architecture** - Review related Models, ViewModels, and Views
3. **Plan incrementally** - Break large features into smaller tasks
4. **Implement with tests** - Add unit tests for business logic
5. **Test both platforms** - Verify on iOS and macOS

## Folder Structure Summary

```
Manuscript/     # Multi-platform app (iOS and macOS)
docs/           # Marketing website (GitHub Pages)
meta/           # Internal docs, feature parity, planning
```
