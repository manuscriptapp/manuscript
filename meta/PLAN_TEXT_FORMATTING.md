# Text Formatting Implementation Plan

**Date:** January 2026
**Status:** Planning
**Author:** Claude Code
**Last Updated:** January 2026

## Executive Summary

This document evaluates options for adding rich text formatting to Manuscript's editor, with the goal of matching Scrivener's professional writing environment. With iOS 26/macOS 26 (released June 2025) introducing native `AttributedString` support in SwiftUI's `TextEditor`, the timing is optimal for implementation. This plan recommends **native SwiftUI with iOS 26+ APIs** as the primary approach, with a clear migration path.

### Target Feature Set (Scrivener Parity)

Manuscript's editor should match Scrivener's core formatting capabilities:

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

**Storage format:**
```
project.manuscript/
├── contents/
│   ├── draft/
│   │   ├── 01-chapter.md    ← Plain Markdown
```

---

## Options Analysis

### Option 1: Native SwiftUI (iOS 26+) ⭐ RECOMMENDED

**Technology:** `TextEditor` + `AttributedString` + `AttributedTextSelection`

iOS 26/macOS 26 (WWDC 2025) introduced first-class rich text editing in SwiftUI.

#### Implementation Example

```swift
struct RichTextEditor: View {
    @Binding var text: AttributedString
    @State private var selection: AttributedTextSelection?
    @Environment(\.fontResolutionContext) private var fontContext

    var body: some View {
        TextEditor(text: $text, selection: $selection)
    }

    func toggleBold() {
        guard let selection else { return }
        text.transformAttributes(in: &selection) { attributes in
            let isBold = attributes.inlinePresentationIntent?.contains(.stronglyEmphasized) ?? false
            if isBold {
                attributes.inlinePresentationIntent?.remove(.stronglyEmphasized)
            } else {
                attributes.inlinePresentationIntent = (attributes.inlinePresentationIntent ?? [])
                    .union(.stronglyEmphasized)
            }
        }
    }
}
```

#### Supported Formatting (Scrivener Feature Parity)

| Feature | iOS 26 Status | Scrivener Match |
|---------|---------------|-----------------|
| **Text Formatting** | | |
| Bold | ✅ Native | ✅ |
| Italic | ✅ Native | ✅ |
| Underline | ✅ Native | ✅ |
| Strikethrough | ✅ Native | ✅ |
| **Font Selection** | | |
| Font family picker | ✅ Native | ✅ |
| Font size | ✅ Native | ✅ |
| Font variants (bold italic) | ✅ Native | ✅ |
| **Colors** | | |
| Text color | ✅ Native | ✅ |
| Highlight/background | ✅ Native | ✅ |
| **Paragraph Formatting** | | |
| Alignment (L/C/R/J) | ✅ Native | ✅ |
| First line indent | ✅ Native (`paragraphStyle`) | ✅ |
| Left/right margins | ✅ Native (`paragraphStyle`) | ✅ |
| Line spacing | ✅ Native (`paragraphStyle`) | ✅ |
| Paragraph spacing | ✅ Native (`paragraphStyle`) | ✅ |
| Tab stops | ✅ Native (`paragraphStyle`) | ✅ |
| **Platform Features** | | |
| Keyboard shortcuts | ✅ Built-in (⌘B, ⌘I, etc.) | ✅ |
| Menu controls | ✅ Built-in | ✅ |
| Writing Tools (iOS 26) | ✅ Native | N/A |
| Genmoji | ✅ Native | N/A |

#### Pros
- **Native Apple solution** – best performance and integration
- **Minimal code** – Apple handles complexity
- **Built-in shortcuts** – ⌘B, ⌘I, ⌘U work automatically
- **Future-proof** – Apple will continue improving
- **Cross-platform** – same code for iOS and macOS
- **Accessibility** – full VoiceOver support built-in
- **Writing Tools integration** – iOS 26 AI writing features

#### Cons
- **iOS 17+ baseline already met** – but requires iOS 26+ for rich text
- **New API quirks** – some features still being refined
- **No backwards compatibility** – users on iOS 17-25 get plain text

#### Minimum Requirements
- iOS 26.0+ / macOS 26.0+
- Xcode 26+
- Swift 5.9+

---

### Option 2: RichTextKit Library

**Technology:** Third-party Swift package wrapping UITextView/NSTextView

[RichTextKit](https://github.com/danielsaidi/RichTextKit) is a mature library (3+ years, 700+ commits) that provides cross-platform rich text editing.

#### Implementation Example

```swift
import RichTextKit

struct Editor: View {
    @State private var context = RichTextContext()
    @State private var text = NSAttributedString(string: "")

    var body: some View {
        VStack {
            RichTextEditor(text: $text, context: context)
            RichTextKeyboardToolbar(context: context)
        }
    }
}
```

#### Pros
- **Backwards compatible** – iOS 14+, macOS 11+
- **Mature and stable** – battle-tested in production apps
- **Rich feature set** – images, lists, toolbars included
- **Active maintenance** – regular updates
- **VisionOS support** – works on Apple Vision Pro

#### Cons
- **Third-party dependency** – additional maintenance burden
- **Uses NSAttributedString** – not Swift-native AttributedString
- **Future unclear** – author questions value post-iOS 26
- **Wraps UIKit/AppKit** – not pure SwiftUI
- **Learning curve** – custom API to learn

#### Minimum Requirements
- iOS 14.0+ / macOS 11.0+
- Swift 5.9+

---

### Option 3: UIKit/AppKit Wrapping (UIViewRepresentable)

**Technology:** Custom `UITextView`/`NSTextView` wrapper

Manually bridge platform text views into SwiftUI.

#### Implementation Example

```swift
// iOS Implementation
struct RichTextView: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }
    }
}

// macOS Implementation
struct RichTextView: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.isRichText = true
        return scrollView
    }
}
```

#### Pros
- **Full control** – complete customization possible
- **TextKit 2 access** – advanced text layout features
- **No dependencies** – pure Apple frameworks
- **Backwards compatible** – iOS 13+, macOS 10.15+

#### Cons
- **Significant complexity** – 500+ lines typical implementation
- **Platform divergence** – UITextView ≠ NSTextView APIs
- **Maintenance burden** – must handle all edge cases
- **Integration friction** – bridging state is error-prone
- **Reinventing the wheel** – Apple solved this in iOS 26

#### Minimum Requirements
- iOS 13.0+ / macOS 10.15+

---

### Option 4: Markdown-Focused Editor

**Technology:** Live syntax highlighting with markdown storage

Keep markdown as the source of truth with live preview/highlighting.

#### Libraries

| Library | Features | Platform |
|---------|----------|----------|
| [HighlightedTextEditor](https://swiftpackageregistry.com/kyle-n/HighlightedTextEditor) | Regex-based highlighting | iOS 13+, macOS 10.15+ |
| [SwiftDown](https://github.com/qeude/SwiftDown) | Live markdown preview | iOS/macOS |
| [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) | Display-only rendering | iOS 15+, macOS 12+ |

#### Implementation Example

```swift
import HighlightedTextEditor

struct MarkdownEditor: View {
    @Binding var text: String

    var body: some View {
        HighlightedTextEditor(text: $text, highlightRules: .markdown)
    }
}
```

#### Pros
- **Manuscript-native** – aligns with markdown storage format
- **Simpler model** – single source of truth
- **Git-friendly** – diffs remain readable
- **Portable** – standard markdown works everywhere

#### Cons
- **Not true WYSIWYG** – users see markdown syntax
- **Limited formatting** – only what markdown supports
- **Learning curve** – users must know markdown
- **No inline images** – markdown syntax for images only

---

### Option 5: Hybrid Approach

**Technology:** Native iOS 26 + graceful degradation

Use iOS 26 native rich text where available, fall back to enhanced plain text on older systems.

#### Implementation Example

```swift
struct AdaptiveEditor: View {
    @Binding var content: String
    @State private var richContent: AttributedString?

    var body: some View {
        if #available(iOS 26, macOS 26, *) {
            RichTextEditorView(text: richContentBinding)
        } else {
            // Fallback: Syntax-highlighted markdown
            HighlightedTextEditor(text: $content, highlightRules: .markdown)
        }
    }

    private var richContentBinding: Binding<AttributedString> {
        Binding(
            get: { richContent ?? AttributedString(content) },
            set: { richContent = $0; content = String($0.characters) }
        )
    }
}
```

#### Pros
- **Best of both worlds** – modern features + compatibility
- **Progressive enhancement** – users get best available
- **Smooth migration** – no forced upgrades

#### Cons
- **Dual maintenance** – two code paths
- **Feature disparity** – different UX per OS version
- **Testing complexity** – must test both paths

---

## Recommendation for 2026

### Primary Recommendation: Native SwiftUI (iOS 26+)

**Rationale:**

1. **Timing is right** – iOS 26 shipped June 2025, adoption is growing
2. **Manuscript's baseline** – already requires iOS 17+, can move to iOS 26+
3. **Minimal code** – Apple handles the hard parts
4. **Best UX** – native keyboard shortcuts, Writing Tools, accessibility
5. **Future-proof** – Apple will continue improving AttributedString
6. **Writing app competitors** – will adopt iOS 26 features; Manuscript should too

### Adoption Timeline

| Phase | Timeline | Action |
|-------|----------|--------|
| Phase 1 | Q1 2026 | Basic formatting + font family selection |
| Phase 2 | Q1 2026 | Paragraph formatting (margins, indents, spacing) |
| Phase 3 | Q2 2026 | Colors + professional toolbar |
| Phase 4 | Q2 2026 | Default formatting settings |
| Phase 5 | Q2 2026 | Persistence & markdown conversion |
| Phase 6 | Q3 2026 | Styles system (optional) |

### OS Support Strategy

**Recommended approach:**
- Raise minimum to **iOS 26 / macOS 26** when implementing
- Manuscript is early-stage; OK to require latest OS
- Users expect writing apps to leverage latest platform features

**Alternative (if backwards compatibility required):**
- Use Hybrid Approach (Option 5)
- iOS 26+: Native rich text
- iOS 17-25: Markdown syntax highlighting

---

## Scrivener Feature Implementation Guide

This section details how to implement each Scrivener-matching feature using iOS 26/macOS 26 native APIs.

### Font Family Selection

Scrivener allows users to select from all installed system fonts. iOS 26's `AttributedString` supports this natively.

```swift
// Font family picker implementation
struct FontFamilyPicker: View {
    @Binding var selectedFont: String

    // Get all available font families on the system
    private var availableFonts: [String] {
        #if os(iOS)
        UIFont.familyNames.sorted()
        #else
        NSFontManager.shared.availableFontFamilies.sorted()
        #endif
    }

    var body: some View {
        Picker("Font", selection: $selectedFont) {
            ForEach(availableFonts, id: \.self) { family in
                Text(family).font(.custom(family, size: 14))
            }
        }
    }
}

// Apply font to AttributedString
func applyFont(_ fontName: String, size: CGFloat, to text: inout AttributedString, in range: Range<AttributedString.Index>) {
    #if os(iOS)
    if let font = UIFont(name: fontName, size: size) {
        text[range].font = font
    }
    #else
    if let font = NSFont(name: fontName, size: size) {
        text[range].font = font
    }
    #endif
}
```

**Cross-Platform Note:** Font names are consistent across iOS and macOS for system fonts. Custom fonts must be bundled with the app and declared in Info.plist.

### Paragraph Formatting (Margins, Indents, Spacing)

Scrivener provides extensive paragraph controls. iOS 26 supports all of these via `NSParagraphStyle` attributes.

```swift
// Paragraph formatting model matching Scrivener's options
struct ParagraphFormat {
    var alignment: NSTextAlignment = .left
    var firstLineIndent: CGFloat = 36  // 0.5 inch (72 points/inch * 0.5)
    var headIndent: CGFloat = 0        // Left margin
    var tailIndent: CGFloat = 0        // Right margin (negative = from right edge)
    var lineSpacing: CGFloat = 0       // Additional line spacing
    var lineHeightMultiple: CGFloat = 1.2  // Scrivener default is 1.2x
    var paragraphSpacingBefore: CGFloat = 0
    var paragraphSpacingAfter: CGFloat = 12  // Space after paragraph
    var tabStops: [NSTextTab] = []

    func toParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.firstLineHeadIndent = firstLineIndent
        style.headIndent = headIndent
        style.tailIndent = tailIndent
        style.lineSpacing = lineSpacing
        style.lineHeightMultiple = lineHeightMultiple
        style.paragraphSpacingBefore = paragraphSpacingBefore
        style.paragraphSpacing = paragraphSpacingAfter
        style.tabStops = tabStops
        return style
    }
}

// Apply paragraph formatting to AttributedString
func applyParagraphFormat(_ format: ParagraphFormat, to text: inout AttributedString, in range: Range<AttributedString.Index>) {
    text[range].paragraphStyle = format.toParagraphStyle()
}
```

### Line Spacing Options

Scrivener offers preset line spacing values. Here's how to implement them:

```swift
enum LineSpacingPreset: String, CaseIterable {
    case single = "1.0"
    case scrivenerDefault = "1.2"
    case oneAndHalf = "1.5"
    case double = "2.0"

    var multiplier: CGFloat {
        switch self {
        case .single: return 1.0
        case .scrivenerDefault: return 1.2
        case .oneAndHalf: return 1.5
        case .double: return 2.0
        }
    }
}

struct LineSpacingPicker: View {
    @Binding var lineHeightMultiple: CGFloat

    var body: some View {
        Picker("Line Spacing", selection: $lineHeightMultiple) {
            ForEach(LineSpacingPreset.allCases, id: \.self) { preset in
                Text(preset.rawValue).tag(preset.multiplier)
            }
        }
    }
}
```

### First Line Indent

Scrivener's default first line indent is 0.5 inches (industry standard). Users can customize this.

```swift
struct IndentControl: View {
    @Binding var firstLineIndent: CGFloat

    // Common presets in points (72 points = 1 inch)
    private let presets: [(String, CGFloat)] = [
        ("None", 0),
        ("0.25\"", 18),
        ("0.5\" (Standard)", 36),
        ("0.75\"", 54),
        ("1\"", 72)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("First Line Indent")
                .font(.headline)

            Picker("", selection: $firstLineIndent) {
                ForEach(presets, id: \.1) { preset in
                    Text(preset.0).tag(preset.1)
                }
            }
            .pickerStyle(.segmented)

            // Custom value slider
            HStack {
                Text("Custom:")
                Slider(value: $firstLineIndent, in: 0...144, step: 9)
                Text(String(format: "%.2f\"", firstLineIndent / 72))
                    .monospacedDigit()
            }
        }
    }
}
```

### Document Margins

Scrivener uses editor margins to create comfortable reading/writing width. This is different from paragraph indents.

```swift
// Editor margin settings (page layout, not paragraph formatting)
struct EditorMargins: Codable, Equatable {
    var left: CGFloat = 40
    var right: CGFloat = 40
    var top: CGFloat = 20
    var bottom: CGFloat = 20

    // Preset widths for reading comfort
    static let narrow = EditorMargins(left: 20, right: 20, top: 20, bottom: 20)
    static let standard = EditorMargins(left: 40, right: 40, top: 20, bottom: 20)
    static let wide = EditorMargins(left: 80, right: 80, top: 30, bottom: 30)
    static let manuscript = EditorMargins(left: 100, right: 100, top: 40, bottom: 40)
}

// Apply to editor view
struct EditorView: View {
    @Binding var text: AttributedString
    @State private var selection: AttributedTextSelection?
    var margins: EditorMargins = .standard

    var body: some View {
        TextEditor(text: $text, selection: $selection)
            .padding(.leading, margins.left)
            .padding(.trailing, margins.right)
            .padding(.top, margins.top)
            .padding(.bottom, margins.bottom)
    }
}
```

### Formatting Palette (Scrivener iOS Style)

Scrivener iOS uses a three-tab formatting palette: Style, Indents, Spacing. Here's the SwiftUI implementation:

```swift
struct FormattingPalette: View {
    @Binding var text: AttributedString
    @Binding var selection: AttributedTextSelection?
    @State private var selectedTab = 0

    var body: some View {
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
            Group {
                switch selectedTab {
                case 0:
                    StyleTab(text: $text, selection: $selection)
                case 1:
                    IndentsTab(text: $text, selection: $selection)
                case 2:
                    SpacingTab(text: $text, selection: $selection)
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .background(.regularMaterial)
    }
}

struct StyleTab: View {
    @Binding var text: AttributedString
    @Binding var selection: AttributedTextSelection?
    @State private var selectedFont = "Palatino"
    @State private var fontSize: CGFloat = 13

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Font picker
            FontFamilyPicker(selectedFont: $selectedFont)

            // Size picker
            HStack {
                Text("Size:")
                Stepper("\(Int(fontSize)) pt", value: $fontSize, in: 8...72)
            }

            // Basic formatting buttons
            HStack(spacing: 12) {
                FormatButton(label: "B", action: toggleBold)
                    .fontWeight(.bold)
                FormatButton(label: "I", action: toggleItalic)
                    .italic()
                FormatButton(label: "U", action: toggleUnderline)
                    .underline()
                FormatButton(label: "S", action: toggleStrikethrough)
                    .strikethrough()
            }

            // Color pickers
            HStack {
                ColorPicker("Text", selection: $textColor)
                ColorPicker("Highlight", selection: $highlightColor)
            }

            // Alignment
            HStack(spacing: 12) {
                AlignmentButton(alignment: .left)
                AlignmentButton(alignment: .center)
                AlignmentButton(alignment: .right)
                AlignmentButton(alignment: .justified)
            }
        }
    }
}
```

### Default Formatting Settings

Like Scrivener, users should be able to set default formatting for new documents:

```swift
// Store default formatting in UserDefaults/AppStorage
struct DefaultFormatSettings: Codable {
    var fontFamily: String = "Palatino"
    var fontSize: CGFloat = 13
    var lineHeightMultiple: CGFloat = 1.2
    var firstLineIndent: CGFloat = 36  // 0.5 inch
    var paragraphSpacing: CGFloat = 0
    var editorMargins: EditorMargins = .standard

    // Convert to AttributedString attributes
    func defaultAttributes() -> AttributeContainer {
        var container = AttributeContainer()
        #if os(iOS)
        container.font = UIFont(name: fontFamily, size: fontSize)
        #else
        container.font = NSFont(name: fontFamily, size: fontSize)
        #endif

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        paragraphStyle.firstLineHeadIndent = firstLineIndent
        paragraphStyle.paragraphSpacing = paragraphSpacing
        container.paragraphStyle = paragraphStyle

        return container
    }
}

// Settings view for default formatting
struct DefaultFormattingSettingsView: View {
    @AppStorage("defaultFormatSettings") private var settingsData: Data?
    @State private var settings = DefaultFormatSettings()

    var body: some View {
        Form {
            Section("Font") {
                FontFamilyPicker(selectedFont: $settings.fontFamily)
                Stepper("Size: \(Int(settings.fontSize)) pt", value: $settings.fontSize, in: 8...72)
            }

            Section("Paragraph") {
                Picker("Line Spacing", selection: $settings.lineHeightMultiple) {
                    Text("1.0").tag(1.0 as CGFloat)
                    Text("1.2 (Scrivener Default)").tag(1.2 as CGFloat)
                    Text("1.5").tag(1.5 as CGFloat)
                    Text("2.0").tag(2.0 as CGFloat)
                }

                IndentControl(firstLineIndent: $settings.firstLineIndent)
            }

            Section("Editor Margins") {
                Picker("Width", selection: $settings.editorMargins) {
                    Text("Narrow").tag(EditorMargins.narrow)
                    Text("Standard").tag(EditorMargins.standard)
                    Text("Wide").tag(EditorMargins.wide)
                    Text("Manuscript").tag(EditorMargins.manuscript)
                }
            }
        }
        .onChange(of: settings) { saveSettings() }
    }
}
```

---

## Implementation Plan

### Phase 1: Foundation (Basic Formatting)

**Goal:** Bold, italic, underline, strikethrough + Font selection

#### Tasks

1. **Update minimum deployment target**
   - Set iOS 26.0 in Xcode project
   - Set macOS 26.0 in Xcode project

2. **Create new rich text model**
   ```swift
   // Models/RichDocument.swift
   struct RichDocument {
       var content: AttributedString
       var notes: AttributedString
       // Conversion to/from markdown for storage
   }
   ```

3. **Create formatting toolbar with font selection**
   ```swift
   // Views/Components/FormattingToolbar.swift
   struct FormattingToolbar: View {
       @Binding var text: AttributedString
       @Binding var selection: AttributedTextSelection?
       @State private var selectedFont = "Palatino"
       @State private var fontSize: CGFloat = 13

       var body: some View {
           HStack {
               // Font family picker (Scrivener-style)
               FontFamilyPicker(selectedFont: $selectedFont)
               Stepper("\(Int(fontSize))", value: $fontSize, in: 8...72)

               Divider()

               // Basic formatting
               Button("B") { toggleBold() }.fontWeight(.bold)
               Button("I") { toggleItalic() }.italic()
               Button("U") { toggleUnderline() }.underline()
               Button("S") { toggleStrikethrough() }.strikethrough()
           }
       }
   }
   ```

4. **Update WriteTab.swift**
   - Replace `TextEditor(text: $viewModel.editedContent)` with rich text version
   - Add `@State var selection: AttributedTextSelection?`
   - Integrate formatting toolbar

5. **Update DocumentDetailViewModel**
   - Change `editedContent: String` to `editedContent: AttributedString`
   - Add formatting state tracking
   - Update save/load logic

### Phase 2: Paragraph Formatting (Scrivener Parity)

**Goal:** Margins, indents, line spacing, paragraph spacing

#### Tasks

1. **Create ParagraphFormat model**
   ```swift
   struct ParagraphFormat: Codable {
       var alignment: NSTextAlignment = .left
       var firstLineIndent: CGFloat = 36  // 0.5" default
       var headIndent: CGFloat = 0
       var tailIndent: CGFloat = 0
       var lineHeightMultiple: CGFloat = 1.2  // Scrivener default
       var paragraphSpacing: CGFloat = 0
   }
   ```

2. **Implement editor margins**
   - Add `EditorMargins` model for page-level padding
   - Apply padding to TextEditor container
   - Store in document settings

3. **Create Scrivener-style formatting palette**
   - Three tabs: Style, Indents, Spacing (matching Scrivener iOS)
   - Implement `IndentsTab` with first line indent, left/right margins
   - Implement `SpacingTab` with line spacing presets and paragraph spacing

4. **First line indent control**
   - Presets: None, 0.25", 0.5" (default), 0.75", 1"
   - Custom value slider

5. **Line spacing presets**
   - 1.0 (single)
   - 1.2 (Scrivener default)
   - 1.5
   - 2.0 (double)
   - Custom value

### Phase 3: Colors & Toolbar

**Goal:** Text/highlight colors + professional toolbar experience

#### Tasks

1. **Color picker integration**
   - Text color picker
   - Highlight/background color picker
   - Recent colors palette

2. **Context-aware toolbar**
   - Show current formatting state (selected font, size, colors)
   - Platform-specific placement:
     - iOS: Paintbrush button → sheet with FormattingPalette (Scrivener-style)
     - macOS: Toolbar + Format menu

3. **Keyboard shortcut registration**
   - Most work automatically with iOS 26 (⌘B, ⌘I, ⌘U)
   - Add custom shortcuts:
     - ⌘T: Show fonts
     - ⌘⇧C: Copy formatting
     - ⌘⇧V: Paste formatting

4. **Format menu (macOS)**
   - Standard Format menu items
   - Submenu for paragraph alignment
   - Submenu for line spacing

### Phase 4: Default Formatting & Settings

**Goal:** User-configurable default formatting (Scrivener feature)

#### Tasks

1. **Default formatting settings**
   - Store in UserDefaults/AppStorage
   - Options: font family, size, line spacing, first indent
   - "Use Current Formatting as Default" button

2. **Settings UI**
   - Add "Default Text Formatting" section to Settings
   - Preview of default formatting
   - Reset to defaults option

3. **Apply defaults to new documents**
   - New documents use saved default formatting
   - Existing documents retain their formatting

### Phase 5: Persistence & Conversion

**Goal:** Save rich text, export to markdown

#### Tasks

1. **AttributedString ↔ Markdown conversion**
   ```swift
   extension AttributedString {
       init(markdown: String) throws {
           // Parse markdown into attributed string
       }

       func toMarkdown() -> String {
           // Convert attributes to markdown syntax
           // Note: Some attributes (margins, colors) may be lost
       }
   }
   ```

2. **File format decision**
   - Option A: Continue markdown storage (with attribute loss)
   - Option B: Store as RTF/RTFD (full fidelity)
   - Option C: Store as JSON-encoded AttributedString
   - **Recommended:** Option C (JSON) for internal storage, export to markdown/RTF

3. **Import/export updates**
   - Update RTFToMarkdownConverter
   - Add AttributedString export options
   - Import RTF with full paragraph formatting

### Phase 6: Styles System (Future)

**Goal:** Paragraph presets like Scrivener (Heading, Block Quote, etc.)

#### Tasks

1. **Define built-in styles**
   - Body text (default)
   - Heading 1, 2, 3
   - Block quote
   - Code block

2. **Style picker UI**
   - Dropdown in formatting palette
   - Quick apply via keyboard shortcuts

3. **Custom style creation**
   - User-defined styles
   - Save current formatting as style

---

## File Changes Summary

| File | Change |
|------|--------|
| `Manuscript.xcodeproj` | Update deployment targets to iOS 26/macOS 26 |
| `WriteTab.swift` | Replace TextEditor, add selection tracking |
| `NotesTab.swift` | Update to AttributedString |
| `DocumentDetailViewModel.swift` | Change content types, add formatting methods |
| `ManuscriptDocument.swift` | Add AttributedString conversion |
| **New:** `Models/ParagraphFormat.swift` | Paragraph formatting model (margins, indents, spacing) |
| **New:** `Models/EditorMargins.swift` | Editor page margins |
| **New:** `Models/DefaultFormatSettings.swift` | User default formatting preferences |
| **New:** `Views/Components/FormattingPalette.swift` | Three-tab formatting UI (Scrivener-style) |
| **New:** `Views/Components/FontFamilyPicker.swift` | System font picker |
| **New:** `Views/Components/IndentControl.swift` | First line indent UI |
| **New:** `Views/Components/LineSpacingPicker.swift` | Line spacing presets |
| **New:** `Views/Settings/DefaultFormattingSettingsView.swift` | Default formatting settings UI |
| **New:** `Extensions/RichTextExtensions.swift` | AttributedString helpers |
| **New:** `Services/MarkdownConverter.swift` | Two-way conversion |

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| iOS 26 adoption too low | User loss | Monitor adoption; consider hybrid approach |
| AttributedString bugs | Data loss | Extensive testing; keep markdown backup |
| Markdown conversion lossy | Formatting loss | Warn users; offer rich format option |
| Performance with large docs | Poor UX | Lazy loading; virtualized text view |

---

## References

### Apple Documentation
- [Building rich SwiftUI text experiences](https://developer.apple.com/documentation/swiftui/building-rich-swiftui-text-experiences)
- [TextEditor Documentation](https://developer.apple.com/documentation/swiftui/texteditor)
- [WWDC25: Rich Text in SwiftUI](https://developer.apple.com/videos/play/wwdc2025/280/)

### Third-Party Resources
- [RichTextKit](https://github.com/danielsaidi/RichTextKit)
- [HighlightedTextEditor](https://swiftpackageregistry.com/kyle-n/HighlightedTextEditor)
- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui)

### Articles
- [Rich Text Editing in SwiftUI — What's New in iOS 26](https://medium.com/@shubhamsanghavi100/rich-text-editing-in-swiftui-whats-new-in-ios-26-xcode-16-4-4d45aed0f0f9)
- [SwiftUI TextEditor/AttributedString/AttributedTextSelection Combo](https://levelup.gitconnected.com/swiftui-the-new-texteditor-attributedstring-attributedtextselection-combo-3f1fa55d3104)
- [Building a Real-Time Pattern Detector with iOS 26's TextEditor](https://dimillian.medium.com/building-a-real-time-pattern-detector-with-ios-26s-texteditor-and-attributedstring-07c0f7b88e32)

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-11 | Recommend native iOS 26 approach | Best UX, minimal code, future-proof |
| 2026-01-11 | Recommend raising min OS to iOS 26 | Manuscript is early-stage; simplifies codebase |
| 2026-01-11 | Keep markdown as storage format | Git-friendly, portable, aligns with project philosophy |
| 2026-01-22 | Match Scrivener formatting features | Font families, margins, indents, spacing for professional writing |
| 2026-01-22 | Use NSParagraphStyle for paragraph formatting | Native iOS 26 support for all paragraph attributes |
| 2026-01-22 | Implement Scrivener-style 3-tab formatting palette | Familiar UX for Scrivener users migrating to Manuscript |
| 2026-01-22 | Default formatting: Palatino 13pt, 1.2 line spacing, 0.5" indent | Match Scrivener defaults for seamless transition |
| 2026-01-22 | Store rich text as JSON-encoded AttributedString | Full fidelity storage, export to markdown/RTF for portability |

## Cross-Platform Implementation Notes

### Font Family Handling

iOS and macOS share most system fonts, but font availability can differ:

```swift
// Safe cross-platform font resolution
func resolveFont(family: String, size: CGFloat) -> Any {
    #if os(iOS)
    return UIFont(name: family, size: size) ?? UIFont.systemFont(ofSize: size)
    #else
    return NSFont(name: family, size: size) ?? NSFont.systemFont(ofSize: size)
    #endif
}
```

### Paragraph Style Compatibility

`NSParagraphStyle` is available on both platforms with identical API. The implementation above works without modification on iOS and macOS.

### Editor Margins

Editor margins are applied via SwiftUI padding, which works identically on both platforms. No platform-specific code needed.

### Formatting Palette UI

The formatting palette uses different presentation styles per platform:
- **iOS:** Sheet presented from paintbrush button (matches Scrivener iOS)
- **macOS:** Popover or inspector panel

```swift
#if os(iOS)
.sheet(isPresented: $showFormatting) {
    FormattingPalette(text: $text, selection: $selection)
}
#else
.popover(isPresented: $showFormatting) {
    FormattingPalette(text: $text, selection: $selection)
        .frame(width: 300, height: 400)
}
#endif
```
