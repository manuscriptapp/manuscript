# Repository Guidelines

## Project Structure & Module Organization
`manuscript/` is the multi-platform SwiftUI app and Xcode project. The main target lives in `manuscript/manuscript/` with subfolders like `Models/`, `ViewModels/`, `Views/` (including `Views/Platform/`), and `Services/`, plus `Assets.xcassets` and `Shaders/`. Tests are split into `manuscript/manuscriptTests/` (unit tests) and `manuscript/manuscriptUITests/` (UI tests). The marketing site is in `docs/` (Jekyll), and internal planning docs live in `meta/`.

## Build, Test, and Development Commands
- Open the Xcode project: `open manuscript/manuscript.xcodeproj`
- Build in Xcode: ⌘B (select iOS or macOS scheme as needed)
- Run locally: ⌘R
- Run tests: ⌘U (runs `manuscriptTests` and `manuscriptUITests`)

## Coding Style & Naming Conventions
- Swift API Design Guidelines are the baseline; keep functions focused and names descriptive.
- Indentation is 4 spaces; match existing formatting and keep brace style consistent.
- Types use `UpperCamelCase`, members and functions use `lowerCamelCase`.
- Keep platform-specific UI in `Views/Platform/` and shared logic in `Models/`, `ViewModels/`, and `Services/`.

## Testing Guidelines
- XCTest is used for both unit and UI tests.
- Add new tests to the appropriate target (`manuscriptTests` for logic, `manuscriptUITests` for UI flows).
- Name test methods with the `test...` prefix and keep them deterministic and platform-aware.

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, and sentence case (e.g., “Add DOCX export format” or “Fix iOS toolbar layout”).
- Use feature branches like `feature/short-description`.
- PRs should describe the change, note iOS/macOS testing coverage, and update docs when behavior or UX changes.

## Documentation & Website
- Product docs and notes live in `meta/`; user-facing marketing content is in `docs/`.
- Keep changes to `docs/` self-contained and verify locally when editing HTML or Jekyll config.
