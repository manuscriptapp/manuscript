# Text Formatting Implementation Plan

**Date:** January 2026
**Status:** Planning
**Author:** Claude Code
**Last Updated:** January 2026

## Executive Summary

This document outlines the implementation of rich text formatting for Manuscript's editor, with the goal of matching Scrivener's professional writing environment while maintaining **iOS 18 / macOS 15 compatibility**.

Since native SwiftUI `AttributedString` editing requires iOS 26+, this plan recommends **RichTextKit** as the primary approach—a mature, cross-platform library that wraps `UITextView`/`NSTextView` and provides full rich text capabilities on iOS 14+.

### Target Feature Set (Scrivener Parity)

| Feature Category | Scrivener Features | Priority |
|-----------------|-------------------|----------|
| **Text Formatting** | Bold, italic, underline, strikethrough | P0 |
| **Font Selection** | Font family picker, font size, font variants | P0 |
| **Colors** | Text color, highlight/background color | P1 |
| **Paragraph** | Alignment (left, center, right, justified) | P1 |
| **Indentation** | First line indent, left/right margins | P1 |
| **Spacing** | Line spacing (1.0, 1.2, 1.5, 2.0), paragraph spacing | P1 |
| **Styles** | Paragraph presets (heading, block quote, etc.) | P2 |
| **Advanced** | Tab stops, ruler display | P3 |

---

## Current State

### Existing Editor Architecture

Manuscript currently uses **plain SwiftUI `TextEditor`** with string bindings:

```swift
// WriteTab.swift (current implementation)
TextEditor(text: $viewModel.editedContent)
```

**Current capabilities:**
- Plain text editing with `String` storage
- Markdown file format for persistence (`.md` files)
- RTF import with markdown conversion
- Selection tracking (custom implementation for iOS/macOS)
- No runtime rich text rendering

---

## Options Analysis

### Option 1: RichTextKit Library ⭐ RECOMMENDED

**Technology:** Third-party Swift package wrapping UITextView/NSTextView

[RichTextKit](https://github.com/danielsaidi/RichTextKit) is a mature library (3+ years, 700+ commits, 31 releases) that provides cross-platform rich text editing.

#### Minimum Requirements
- **iOS 14.0+** / macOS 11.0+ ✅ Works with iOS 18
- Swift 5.9+
- SwiftUI

#### Supported Formatting (Scrivener Feature Parity)

| Feature | RichTextKit Support | Scrivener Match |
|---------|---------------------|-----------------|
| **Text Formatting** | | |
| Bold | ✅ `RichTextStyle.bold` | ✅ |
| Italic | ✅ `RichTextStyle.italic` | ✅ |
| Underline | ✅ `RichTextStyle.underlined` | ✅ |
| Strikethrough | ✅ `RichTextStyle.strikethrough` | ✅ |
| **Font Selection** | | |
| Font family picker | ✅ `RichTextFont.Picker` | ✅ |
| Font size | ✅ `RichTextFont.SizePicker` | ✅ |
| Font variants | ✅ Via NSAttributedString | ✅ |
| **Colors** | | |
| Text color | ✅ `RichTextColor.Picker` | ✅ |
| Highlight/background | ✅ `RichTextColor.Picker` | ✅ |
| **Paragraph Formatting** | | |
| Alignment (L/C/R/J) | ✅ `RichTextAlignment` | ✅ |
| First line indent | ✅ Via `NSParagraphStyle` | ✅ |
| Left/right margins | ✅ Via `NSParagraphStyle` | ✅ |
| Line spacing | ✅ `RichTextLine.SpacingPicker` | ✅ |
| Paragraph spacing | ✅ Via `NSParagraphStyle` | ✅ |
| Tab stops | ✅ Via `NSParagraphStyle` | ✅ |
| **Platform Features** | | |
| Keyboard shortcuts | ✅ Built-in | ✅ |
| iOS keyboard toolbar | ✅ `RichTextKeyboardToolbar` | ✅ |
| macOS format menu | ⚠️ Custom implementation | ✅ |

#### Implementation Example

```swift
import SwiftUI
import RichTextKit

struct ManuscriptEditor: View {
    @State private var text = NSAttributedString(string: "")
    @StateObject private var context = RichTextContext()

    var body: some View {
        VStack(spacing: 0) {
            RichTextEditor(text: $text, context: context)
                .focusedValue(\.richTextContext, context)

            #if os(iOS)
            RichTextKeyboardToolbar(
                context: context,
                leadingButtons: { $0 },
                trailingButtons: { $0 },
                formatSheet: { $0 }
            )
            #endif
        }
        #if os(macOS)
        .toolbar {
            ToolbarItemGroup {
                RichTextFont.Picker(selection: $context.fontName, values: [])
                RichTextFont.SizePicker(selection: $context.fontSize)
                RichTextStyle.ToggleGroup(context: context)
                RichTextAlignment.Picker(selection: $context.textAlignment)
            }
        }
        #endif
    }
}
```

#### Pros
- **iOS 18 compatible** – works on iOS 14+, macOS 11+
- **Mature and stable** – 3+ years of development, battle-tested
- **Rich feature set** – fonts, colors, alignments, images, toolbars
- **Cross-platform** – same API for iOS and macOS
- **Active maintenance** – recently updated to Swift 6
- **Built-in UI components** – pickers, toolbars, format sheets
- **NSParagraphStyle support** – full paragraph formatting

#### Cons
- **Third-party dependency** – additional maintenance consideration
- **Uses NSAttributedString** – not Swift-native AttributedString
- **Future unclear** – author notes iOS 26 may reduce library value
- **Wraps UIKit/AppKit** – not pure SwiftUI

---

### Option 2: Custom UITextView/NSTextView Wrapper

**Technology:** Manual `UIViewRepresentable`/`NSViewRepresentable` implementation

Build a custom wrapper around platform text views for maximum control.

#### Minimum Requirements
- iOS 13.0+ / macOS 10.15+

#### Pros
- **Full control** – complete customization
- **No dependencies** – pure Apple frameworks
- **TextKit 2 access** – advanced layout features

#### Cons
- **Significant complexity** – 500+ lines typical implementation
- **Platform divergence** – UITextView ≠ NSTextView APIs
- **Maintenance burden** – must handle all edge cases
- **Reinventing the wheel** – RichTextKit already solved this

**Recommendation:** Use RichTextKit instead of building custom wrapper.

---

### Option 3: Native SwiftUI (iOS 26+) – Future Option

**Technology:** `TextEditor` + `AttributedString` + `AttributedTextSelection`

When Manuscript raises minimum to iOS 26, can migrate to native implementation.

#### Migration Path
```swift
// Future: iOS 26+ native approach
struct AdaptiveEditor: View {
    var body: some View {
        if #available(iOS 26, macOS 26, *) {
            // Native AttributedString TextEditor
            NativeRichTextEditor(text: $richText, selection: $selection)
        } else {
            // RichTextKit fallback
            RichTextEditor(text: $nsAttributedText, context: context)
        }
    }
}
```

---

## Recommendation: RichTextKit

### Why RichTextKit for iOS 18

1. **Immediate availability** – works today on iOS 18
2. **Scrivener feature parity** – supports all required formatting
3. **Cross-platform** – single codebase for iOS and macOS
4. **Built-in components** – font pickers, toolbars, format sheets
5. **NSParagraphStyle support** – margins, indents, spacing
6. **Active maintenance** – Swift 6 compatible
7. **Clear migration path** – can move to native iOS 26 later

### Adoption Timeline

| Phase | Timeline | Action |
|-------|----------|--------|
| Phase 1 | Q1 2026 | Add RichTextKit, basic formatting (bold/italic/underline) |
| Phase 2 | Q1 2026 | Font family picker, font sizes |
| Phase 3 | Q2 2026 | Paragraph formatting (margins, indents, spacing) |
| Phase 4 | Q2 2026 | Colors, alignment, keyboard toolbar |
| Phase 5 | Q2 2026 | Default formatting settings |
| Phase 6 | Q3 2026 | Persistence & markdown conversion |
| Future | 2027+ | Migrate to native iOS 26 when min OS raised |

---

## Scrivener Feature Implementation Guide

This section details how to implement each Scrivener-matching feature using RichTextKit.

### Setup: Adding RichTextKit

```swift
// Package.swift or Xcode SPM
dependencies: [
    .package(url: "https://github.com/danielsaidi/RichTextKit.git", from: "1.0.0")
]
```

### Basic Editor Setup

```swift
import SwiftUI
import RichTextKit

struct WriteTab: View {
    @Binding var document: ManuscriptDocument.Document
    @StateObject private var context = RichTextContext()
    @State private var attributedText: NSAttributedString = NSAttributedString()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar (macOS) or inline controls
            #if os(macOS)
            FormattingToolbar(context: context)
            Divider()
            #endif

            // Rich text editor
            RichTextEditor(text: $attributedText, context: context)
                .richTextEditorMargins(horizontal: 40, vertical: 20)
                .focusedValue(\.richTextContext, context)

            // Keyboard toolbar (iOS)
            #if os(iOS)
            RichTextKeyboardToolbar(
                context: context,
                leadingButtons: { $0 },
                trailingButtons: { $0 },
                formatSheet: { $0 }
            )
            #endif
        }
        .onAppear { loadContent() }
        .onChange(of: attributedText) { saveContent() }
    }
}
```

### Font Family Selection

RichTextKit provides built-in font pickers that work cross-platform:

```swift
struct FormattingToolbar: View {
    @ObservedObject var context: RichTextContext

    var body: some View {
        HStack(spacing: 12) {
            // Font family picker - shows all system fonts
            RichTextFont.Picker(
                selection: $context.fontName,
                values: [] // Empty = all system fonts
            )
            .frame(width: 150)

            // Font size picker
            RichTextFont.SizePicker(
                selection: $context.fontSize
            )
            .frame(width: 60)

            Divider().frame(height: 20)

            // Style toggles
            RichTextStyle.ToggleGroup(context: context)

            Divider().frame(height: 20)

            // Alignment picker
            RichTextAlignment.Picker(selection: $context.textAlignment)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
```

### Paragraph Formatting (Margins, Indents, Spacing)

RichTextKit supports `NSParagraphStyle` for full paragraph control:

```swift
// Paragraph formatting model matching Scrivener's options
struct ParagraphFormat {
    var alignment: NSTextAlignment = .left
    var firstLineIndent: CGFloat = 36  // 0.5 inch (72 points/inch * 0.5)
    var headIndent: CGFloat = 0        // Left margin
    var tailIndent: CGFloat = 0        // Right margin
    var lineSpacing: CGFloat = 0
    var lineHeightMultiple: CGFloat = 1.2  // Scrivener default
    var paragraphSpacingBefore: CGFloat = 0
    var paragraphSpacingAfter: CGFloat = 12

    func toParagraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.firstLineHeadIndent = firstLineIndent
        style.headIndent = headIndent
        style.tailIndent = tailIndent
        style.lineSpacing = lineSpacing
        style.lineHeightMultiple = lineHeightMultiple
        style.paragraphSpacingBefore = paragraphSpacingBefore
        style.paragraphSpacing = paragraphSpacingAfter
        return style
    }
}

// Apply paragraph formatting via RichTextContext
extension RichTextContext {
    func applyParagraphFormat(_ format: ParagraphFormat) {
        // RichTextKit uses NSAttributedString attributes
        let style = format.toParagraphStyle()
        // Apply to current selection or typing attributes
        self.setStyle(.paragraphStyle, to: style)
    }
}
```

### Line Spacing Options

```swift
struct LineSpacingControl: View {
    @ObservedObject var context: RichTextContext
    @State private var lineSpacing: CGFloat = 1.2

    private let presets: [(String, CGFloat)] = [
        ("1.0", 1.0),
        ("1.2", 1.2),  // Scrivener default
        ("1.5", 1.5),
        ("2.0", 2.0)
    ]

    var body: some View {
        Picker("Line Spacing", selection: $lineSpacing) {
            ForEach(presets, id: \.1) { preset in
                Text(preset.0).tag(preset.1)
            }
        }
        .onChange(of: lineSpacing) { newValue in
            applyLineSpacing(newValue)
        }
    }

    private func applyLineSpacing(_ multiple: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = multiple
        // Apply via context or directly to attributed string
    }
}
```

### First Line Indent

```swift
struct FirstLineIndentControl: View {
    @ObservedObject var context: RichTextContext
    @State private var indent: CGFloat = 36  // 0.5 inch default

    private let presets: [(String, CGFloat)] = [
        ("None", 0),
        ("0.25\"", 18),
        ("0.5\"", 36),   // Standard
        ("0.75\"", 54),
        ("1\"", 72)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("First Line Indent")
                .font(.headline)

            Picker("", selection: $indent) {
                ForEach(presets, id: \.1) { preset in
                    Text(preset.0).tag(preset.1)
                }
            }
            .pickerStyle(.segmented)

            // Custom slider
            HStack {
                Slider(value: $indent, in: 0...144, step: 9)
                Text(String(format: "%.2f\"", indent / 72))
                    .monospacedDigit()
                    .frame(width: 50)
            }
        }
        .onChange(of: indent) { applyIndent($0) }
    }

    private func applyIndent(_ points: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = points
        // Apply to context
    }
}
```

### Editor Margins

Editor margins in RichTextKit are set via view modifiers:

```swift
struct EditorMargins: Codable, Equatable {
    var horizontal: CGFloat = 40
    var vertical: CGFloat = 20

    static let narrow = EditorMargins(horizontal: 20, vertical: 15)
    static let standard = EditorMargins(horizontal: 40, vertical: 20)
    static let wide = EditorMargins(horizontal: 80, vertical: 30)
    static let manuscript = EditorMargins(horizontal: 100, vertical: 40)
}

// Apply to RichTextEditor
RichTextEditor(text: $text, context: context)
    .richTextEditorMargins(
        horizontal: margins.horizontal,
        vertical: margins.vertical
    )
```

### Scrivener-Style Formatting Palette (iOS)

Create a three-tab formatting palette matching Scrivener iOS:

```swift
struct FormattingPalette: View {
    @ObservedObject var context: RichTextContext
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Style").tag(0)
                    Text("Indents").tag(1)
                    Text("Spacing").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Tab content
                TabView(selection: $selectedTab) {
                    StyleTabContent(context: context).tag(0)
                    IndentsTabContent(context: context).tag(1)
                    SpacingTabContent(context: context).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Format")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StyleTabContent: View {
    @ObservedObject var context: RichTextContext

    var body: some View {
        Form {
            Section("Font") {
                RichTextFont.Picker(
                    selection: $context.fontName,
                    values: []
                )

                HStack {
                    Text("Size")
                    Spacer()
                    RichTextFont.SizePicker(selection: $context.fontSize)
                }
            }

            Section("Style") {
                RichTextStyle.ToggleStack(context: context)
            }

            Section("Color") {
                RichTextColor.Picker(
                    type: .foreground,
                    value: $context.foregroundColor
                )
                RichTextColor.Picker(
                    type: .background,
                    value: $context.backgroundColor
                )
            }

            Section("Alignment") {
                RichTextAlignment.Picker(selection: $context.textAlignment)
            }
        }
    }
}

struct IndentsTabContent: View {
    @ObservedObject var context: RichTextContext

    var body: some View {
        Form {
            Section("First Line") {
                FirstLineIndentControl(context: context)
            }

            Section("Margins") {
                // Left/right margin controls
            }
        }
    }
}

struct SpacingTabContent: View {
    @ObservedObject var context: RichTextContext

    var body: some View {
        Form {
            Section("Line Spacing") {
                LineSpacingControl(context: context)
            }

            Section("Paragraph Spacing") {
                // Before/after paragraph spacing
            }
        }
    }
}
```

### Default Formatting Settings

```swift
struct DefaultFormatSettings: Codable {
    var fontFamily: String = "Palatino"
    var fontSize: CGFloat = 13
    var lineHeightMultiple: CGFloat = 1.2
    var firstLineIndent: CGFloat = 36  // 0.5 inch
    var paragraphSpacing: CGFloat = 0
    var editorMargins: EditorMargins = .standard

    // Convert to NSAttributedString attributes
    func defaultAttributes() -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]

        // Font
        #if os(iOS)
        if let font = UIFont(name: fontFamily, size: fontSize) {
            attributes[.font] = font
        }
        #else
        if let font = NSFont(name: fontFamily, size: fontSize) {
            attributes[.font] = font
        }
        #endif

        // Paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        paragraphStyle.firstLineHeadIndent = firstLineIndent
        paragraphStyle.paragraphSpacing = paragraphSpacing
        attributes[.paragraphStyle] = paragraphStyle

        return attributes
    }
}

// Settings view
struct DefaultFormattingSettingsView: View {
    @AppStorage("defaultFontFamily") private var fontFamily = "Palatino"
    @AppStorage("defaultFontSize") private var fontSize: Double = 13
    @AppStorage("defaultLineSpacing") private var lineSpacing: Double = 1.2
    @AppStorage("defaultFirstIndent") private var firstIndent: Double = 36

    var body: some View {
        Form {
            Section("Font") {
                Picker("Family", selection: $fontFamily) {
                    ForEach(availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }

                Stepper("Size: \(Int(fontSize)) pt", value: $fontSize, in: 8...72)
            }

            Section("Paragraph") {
                Picker("Line Spacing", selection: $lineSpacing) {
                    Text("1.0").tag(1.0)
                    Text("1.2 (Default)").tag(1.2)
                    Text("1.5").tag(1.5)
                    Text("2.0").tag(2.0)
                }

                Picker("First Line Indent", selection: $firstIndent) {
                    Text("None").tag(0.0)
                    Text("0.25\"").tag(18.0)
                    Text("0.5\" (Standard)").tag(36.0)
                    Text("0.75\"").tag(54.0)
                    Text("1\"").tag(72.0)
                }
            }
        }
        .navigationTitle("Default Formatting")
    }

    private var availableFonts: [String] {
        #if os(iOS)
        UIFont.familyNames.sorted()
        #else
        NSFontManager.shared.availableFontFamilies.sorted()
        #endif
    }
}
```

---

## Implementation Plan

### Phase 1: Foundation (RichTextKit Integration)

**Goal:** Add RichTextKit, basic formatting (bold, italic, underline, strikethrough)

#### Tasks

1. **Add RichTextKit dependency**
   ```swift
   // Package dependency
   .package(url: "https://github.com/danielsaidi/RichTextKit.git", from: "1.0.0")
   ```

2. **Create RichTextEditor wrapper**
   - Replace plain `TextEditor` with `RichTextEditor`
   - Add `RichTextContext` state object
   - Wire up text binding

3. **Add basic formatting toolbar**
   - Bold, italic, underline, strikethrough toggles
   - Use `RichTextStyle.ToggleGroup`

4. **Update DocumentDetailViewModel**
   - Change `editedContent: String` to `NSAttributedString`
   - Add context management

### Phase 2: Font Selection

**Goal:** Font family picker, font sizes

#### Tasks

1. **Add font picker**
   - Use `RichTextFont.Picker` for family selection
   - Use `RichTextFont.SizePicker` for size

2. **Create FormattingToolbar view**
   - Platform-specific layout (macOS toolbar, iOS sheet)

### Phase 3: Paragraph Formatting

**Goal:** Margins, indents, line spacing, paragraph spacing

#### Tasks

1. **Create ParagraphFormat model**
2. **Implement first line indent control**
3. **Implement line spacing picker**
4. **Add editor margins support**
5. **Create Scrivener-style 3-tab formatting palette**

### Phase 4: Colors & Polish

**Goal:** Text/highlight colors, professional UI

#### Tasks

1. **Add color pickers**
   - `RichTextColor.Picker` for foreground
   - `RichTextColor.Picker` for background/highlight

2. **iOS keyboard toolbar**
   - Configure `RichTextKeyboardToolbar`
   - Add format sheet trigger

3. **macOS Format menu**
   - Standard menu items
   - Keyboard shortcuts

### Phase 5: Default Formatting Settings

**Goal:** User-configurable defaults (Scrivener feature)

#### Tasks

1. **Create DefaultFormatSettings model**
2. **Add settings UI**
3. **Apply defaults to new documents**

### Phase 6: Persistence & Conversion

**Goal:** Save rich text, export to markdown

#### Tasks

1. **NSAttributedString ↔ Markdown conversion**
   - Bold, italic → `**text**`, `*text*`
   - Preserve what markdown supports
   - Warn about formatting loss

2. **File format options**
   - Option A: Store as RTF (full fidelity)
   - Option B: Store as archived NSAttributedString
   - Option C: Continue markdown with metadata sidecar
   - **Recommended:** RTF for internal storage, export to markdown

3. **Import/export**
   - RTF import (native support)
   - Markdown export
   - DOCX export (future)

---

## File Changes Summary

| File | Change |
|------|--------|
| `Package.swift` or Xcode | Add RichTextKit dependency |
| `WriteTab.swift` | Replace TextEditor with RichTextEditor |
| `NotesTab.swift` | Update to use RichTextEditor |
| `DocumentDetailViewModel.swift` | Change to NSAttributedString, add context |
| `ManuscriptDocument.swift` | Update persistence for rich text |
| **New:** `Models/ParagraphFormat.swift` | Paragraph formatting model |
| **New:** `Models/EditorMargins.swift` | Editor margins |
| **New:** `Models/DefaultFormatSettings.swift` | Default formatting |
| **New:** `Views/Components/FormattingToolbar.swift` | macOS toolbar |
| **New:** `Views/Components/FormattingPalette.swift` | iOS 3-tab palette |
| **New:** `Views/Settings/DefaultFormattingSettingsView.swift` | Settings UI |
| **New:** `Services/MarkdownConverter.swift` | Two-way conversion |

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| RichTextKit maintenance | Dependency risk | Library is mature; can fork if needed |
| NSAttributedString complexity | Development time | RichTextKit abstracts most complexity |
| Markdown conversion lossy | Formatting loss | Warn users; offer RTF format option |
| Performance with large docs | Poor UX | Test with large documents; optimize |
| Future iOS 26 migration | Rework needed | Design with migration in mind |

---

## References

### RichTextKit
- [GitHub Repository](https://github.com/danielsaidi/RichTextKit)
- [Swift Package Index](https://swiftpackageindex.com/danielsaidi/RichTextKit)
- [Building a rich text editor for UIKit, AppKit and SwiftUI](https://danielsaidi.com/blog/2022/06/13/building-a-rich-text-editor-for-uikit-appkit-and-swiftui)

### Alternative Libraries
- [STTextView](https://github.com/krzyzanowskim/STTextView) - TextKit 2 based
- [HighlightedTextEditor](https://github.com/kyle-n/HighlightedTextEditor) - Markdown highlighting

### Scrivener Reference
- [Scrivener iOS: Formatting Palette](https://www.literatureandlatte.com/blog/scrivener-ios-formatting-palette)
- [How to Use the Format Bar and Ruler](https://www.literatureandlatte.com/blog/how-to-use-the-format-bar-header-bar-and-ruler-in-scriveners-editor)
- [Setting up default formatting in Scrivener 3](https://gwenhernandez.com/2024/10/28/setting-up-default-formatting-in-scrivener-3/)

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-22 | Use RichTextKit for iOS 18 compatibility | Native iOS 26 APIs not available; RichTextKit is mature and full-featured |
| 2026-01-22 | Match Scrivener formatting features | Font families, margins, indents, spacing for professional writing |
| 2026-01-22 | Default formatting: Palatino 13pt, 1.2 line spacing, 0.5" indent | Match Scrivener defaults |
| 2026-01-22 | Store rich text as RTF | Full fidelity; native support on both platforms |
| 2026-01-22 | Plan migration path to iOS 26 native | Future-proof architecture |
