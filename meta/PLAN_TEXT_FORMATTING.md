# Text Formatting Implementation Plan

**Date:** January 2026
**Status:** Planning
**Author:** Claude Code

## Executive Summary

This document evaluates options for adding rich text formatting to Manuscript's editor. With iOS 26/macOS 26 (released June 2025) introducing native `AttributedString` support in SwiftUI's `TextEditor`, the timing is optimal for implementation. This plan recommends **native SwiftUI with iOS 26+ APIs** as the primary approach, with a clear migration path.

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

#### Supported Formatting

| Feature | Status |
|---------|--------|
| Bold | ✅ Native |
| Italic | ✅ Native |
| Underline | ✅ Native |
| Strikethrough | ✅ Native |
| Custom fonts | ✅ Native |
| Font sizes | ✅ Native |
| Text colors | ✅ Native |
| Background colors | ✅ Native |
| Kerning/tracking | ✅ Native |
| Baseline offset | ✅ Native |
| Paragraph alignment | ✅ Native |
| Line height | ✅ Native |
| Genmoji | ✅ Native |
| Keyboard shortcuts | ✅ Built-in (⌘B, ⌘I, etc.) |
| Menu controls | ✅ Built-in |

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
| Phase 1 | Q1 2026 | Implement basic formatting (bold, italic, underline) |
| Phase 2 | Q2 2026 | Add font/size/color customization |
| Phase 3 | Q2 2026 | Toolbar and keyboard shortcuts |
| Phase 4 | Q3 2026 | Markdown ↔ AttributedString conversion |

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

## Implementation Plan

### Phase 1: Foundation (Basic Formatting)

**Goal:** Bold, italic, underline, strikethrough

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

3. **Create formatting toolbar**
   ```swift
   // Views/Components/FormattingToolbar.swift
   struct FormattingToolbar: View {
       @Binding var text: AttributedString
       @Binding var selection: AttributedTextSelection?

       var body: some View {
           HStack {
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

### Phase 2: Extended Formatting

**Goal:** Fonts, sizes, colors

#### Tasks

1. **Font picker component**
   ```swift
   struct FontPicker: View {
       @Binding var selection: Font?
       let fonts: [Font] = [.body, .title, .headline, .caption]
   }
   ```

2. **Color picker integration**
   - Foreground color
   - Background/highlight color

3. **Size adjustment**
   - Predefined sizes (Small, Normal, Large, Huge)
   - Custom point size input

### Phase 3: Toolbar & Shortcuts

**Goal:** Professional editing experience

#### Tasks

1. **Context-aware toolbar**
   - Show current formatting state
   - Platform-specific placement (iOS bottom, macOS top)

2. **Keyboard shortcut registration**
   - Most work automatically with iOS 26
   - Add custom shortcuts for app-specific features

3. **Format menu (macOS)**
   - Standard Format menu items
   - Integration with system menu bar

### Phase 4: Persistence & Conversion

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
       }
   }
   ```

2. **File format decision**
   - Option A: Continue markdown storage (with attribute loss)
   - Option B: Store as RTF/RTFD (full fidelity)
   - Option C: Store as JSON-encoded AttributedString
   - **Recommended:** Option A with optional B for "rich" documents

3. **Import/export updates**
   - Update RTFToMarkdownConverter
   - Add AttributedString export options

---

## File Changes Summary

| File | Change |
|------|--------|
| `Manuscript.xcodeproj` | Update deployment targets to iOS 26/macOS 26 |
| `WriteTab.swift` | Replace TextEditor, add selection tracking |
| `NotesTab.swift` | Update to AttributedString |
| `DocumentDetailViewModel.swift` | Change content types, add formatting methods |
| `ManuscriptDocument.swift` | Add AttributedString conversion |
| **New:** `FormattingToolbar.swift` | Formatting UI component |
| **New:** `RichTextExtensions.swift` | AttributedString helpers |
| **New:** `MarkdownConverter.swift` | Two-way conversion |

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
