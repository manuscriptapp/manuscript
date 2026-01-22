# iOS Version Research for Manuscript

*Research conducted January 2026*

This document summarizes research on iOS 18, iOS 26 (and macOS equivalents) to inform decisions about minimum deployment targets for Manuscript.

## Current State

- **Current target**: iOS 18.0 / macOS 15.0 (Sequoia) *(updated January 2026)*
- **Previous target**: iOS 17.0 / macOS 14.0 (Sonoma)
- **Future consideration**: iOS 26 / macOS 26 (Tahoe) when adoption increases

### Implemented iOS 18 Features
- **DocumentGroupLaunchScene** - Custom document launch experience with branded background and template picker
- **NewDocumentButton** with async template creation

---

## Version Naming

Apple changed versioning at WWDC 2025 — all platforms now use "26" to match the 2025-2026 release cycle:

| Platform | Version | Codename |
|----------|---------|----------|
| iOS | 26 | — |
| iPadOS | 26 | — |
| macOS | 26 | **Tahoe** |
| watchOS | 26 | — |
| tvOS | 26 | — |
| visionOS | 26 | — |

*(Versions 16-25 were skipped for macOS to align everything)*

---

## Adoption Rates (January 2026)

### iOS

| Version | TelemetryDeck | Notes |
|---------|---------------|-------|
| **iOS 26** | ~55% | Growing, but slower than typical |
| **iOS 18** | ~40% | Still substantial |
| Older | ~5% | iOS 17 and below |

iOS 26 adoption is slower due to:
- Liquid Glass redesign received mixed reactions
- Apple provides security updates for iOS 18, reducing upgrade pressure

### macOS

| Version | Share (Dec 2025) |
|---------|------------------|
| **macOS 26.2 (Tahoe)** | ~30% |
| **macOS 26.1** | ~19% |
| **macOS 26.0** | ~3% |
| **macOS 15.7 (Sequoia)** | ~25% |
| Older | ~23% |

**macOS 26 Tahoe total**: ~52%

### Target Reach

| Target | User Reach | Trade-off |
|--------|------------|-----------|
| iOS 17 / macOS 14 (current) | ~95%+ | Missing iOS 18 features |
| iOS 18 / macOS 15 | ~90-95% | Good balance, mature APIs |
| iOS 26 / macOS 26 | ~50-55% | Cuts half your users |

---

## iOS 18 / macOS 15 Features

### DocumentGroup Improvements

New `DocumentGroupLaunchScene` — customizable welcome screen before the file browser:

```swift
@main
struct ManuscriptApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ManuscriptDocument()) { file in
            ContentView(document: file.$document)
        }

        // New in iOS 18
        DocumentGroupLaunchScene {
            NewDocumentButton("New Manuscript")
            NewDocumentButton("Choose Template") {
                return try await pickTemplate()
            }
        } background: {
            Image("launchBackground").resizable()
        } overlayAccessoryView: { geometry in
            Image("quill")
                .position(x: geometry.titleFrame.maxX + 20,
                         y: geometry.titleFrame.midY)
        }
    }
}
```

**Customizable elements:**
- Background (images, gradients, animated views)
- Title with custom styling
- Action buttons ("New Manuscript", "Choose Template", "Open Recent")
- Accessory views (decorative illustrations)
- Entry animations

### TextEditor

- `writingToolsBehavior` modifier — Control Apple Intelligence Writing Tools integration
- Text selection binding — Direct access to selection state

### NavigationSplitView

- **Tab Bar ↔ Sidebar Adaptability**: `.tabViewStyle(.sidebarAdaptable)` lets users switch between tab bar and sidebar on iPad
- **Bug Fix**: `DismissAction` in columns now properly pops navigation stack
- **Bug Fix**: Column visibility toggle no longer gets stuck
- **Sidebar width**: Still finicky, mixed reports on whether `.navigationSplitViewColumnWidth()` works reliably

### Other

- Sidebar width fix for iPadOS (was broken in 16/17)
- Metal shader precompilation
- `@Entry` macro for cleaner custom environment values

---

## iOS 26 / macOS 26 Features

### TextEditor with AttributedString

The major addition for writing apps:

```swift
@State private var text: AttributedString = ""
@State private var selection = AttributedTextSelection()

TextEditor(text: $text, selection: $selection)
```

#### Confirmed Supported Attributes

**Character-Level:**
```swift
container.font = .body.bold()           // Bold
container.font = .body.italic()         // Italic
container.underlineStyle = .single      // Underline
container.strikethroughStyle = .single  // Strikethrough
container.foregroundColor = .red        // Text color
container.backgroundColor = .yellow     // Highlight
container.kern = 1.5                    // Letter spacing
container.baselineOffset = 2            // Baseline
container.link = URL(...)               // Links
```

**Paragraph-Level:**
```swift
container.alignment = .right            // Text alignment
// Line height - supported
// Writing direction - auto-detected
```

**Built-in keyboard shortcuts:** Bold (⌘B), Italic (⌘I), etc. work automatically.

#### NOT Documented as Supported

| Property | Status |
|----------|--------|
| `headIndent` | Not mentioned in any source |
| `firstLineHeadIndent` | Not mentioned |
| `tabStops` | Not mentioned |
| `paragraphSpacing` | Not mentioned |
| `lineSpacing` (as attribute) | Not mentioned |
| `lineHeightMultiple` | Not mentioned |

#### Verdict

iOS 26 TextEditor is great for **rich notes** (Apple Notes level) but lacks paragraph formatting control for **manuscript editing** (Scrivener level).

For full paragraph control, UIKit bridge is still needed:
```swift
let style = NSMutableParagraphStyle()
style.firstLineHeadIndent = 36  // Book-style indent
style.headIndent = 0
style.tabStops = [NSTextTab(textAlignment: .left, location: 72)]
style.paragraphSpacing = 12
```

### Liquid Glass Design

Apps automatically get the new visual language by building with Xcode 26. One-year opt-out grace period available.

### SwiftData

- **Model inheritance** — Define base classes, extend with subclasses
- Various bug fixes from iOS 18 issues

### Other

- Native WebView in SwiftUI (no UIViewRepresentable needed)
- Major List/scrollable view performance improvements on macOS
- New Instruments template for SwiftUI profiling

---

## Comparison: iOS 26 TextEditor vs Scrivener Requirements

| Feature | iOS 26 TextEditor | Scrivener Needs |
|---------|-------------------|-----------------|
| Bold/Italic/Underline | ✅ | ✅ |
| Font size | ✅ | ✅ |
| Text color | ✅ | ✅ |
| Text alignment | ✅ | ✅ |
| Line height | ✅ | ✅ |
| First line indent | ❌ | ✅ |
| Paragraph indent | ❌ | ✅ |
| Tab stops | ❌ | ✅ |
| Paragraph spacing | ❌ | ✅ |
| Style presets | ❌ | ✅ |
| Tables | ❌ | ✅ |
| Inline images | ❌ | ✅ |
| Footnotes | ❌ | ✅ |
| Comments/annotations | ❌ | ✅ |
| Ruler UI | ❌ | ✅ |

---

## Recommendations for Manuscript

### Short-term
Bump to **iOS 18 / macOS 15** to get:
- DocumentGroupLaunchScene for branded launch experience
- Writing Tools integration
- Bug fixes for NavigationSplitView
- ~95% user reach

### Medium-term (Late 2026)
Once iOS 26 reaches 80%+ adoption, consider requiring it for:
- Native AttributedString in TextEditor (basic rich text)
- Liquid Glass design
- SwiftData model inheritance

### For Full Rich Text Editor
Continue using **UITextView/NSTextView bridge** with TextKit 2 for:
- Full paragraph style control
- Ruler with tab stops and indents
- Inline annotations
- Style presets

Consider [RichTextKit](https://github.com/danielsaidi/RichTextKit) library for cross-platform rich text.

### Hybrid Approach
```swift
#if canImport(UIKit)
@available(iOS 26, *)
struct ModernEditor: View {
    @State private var text: AttributedString = ""
    var body: some View {
        TextEditor(text: $text)
    }
}

struct LegacyEditor: UIViewRepresentable {
    // Full UITextView with TextKit 2
}
#endif
```

---

## Sources

- [Evolve your document launch experience - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10132/)
- [What's new in SwiftUI for iOS 18 - Hacking with Swift](https://www.hackingwithswift.com/articles/270/whats-new-in-swiftui-for-ios-18)
- [Code-along: Rich text with AttributedString - WWDC25](https://developer.apple.com/videos/play/wwdc2025/280/)
- [iOS Versions Market Share - TelemetryDeck](https://telemetrydeck.com/survey/apple/iOS/majorSystemVersions/)
- [macOS Versions Market Share - TelemetryDeck](https://telemetrydeck.com/survey/apple/macOS/versions/)
- [macOS Tahoe - Wikipedia](https://en.wikipedia.org/wiki/MacOS_Tahoe)
- [SwiftUI Split View Configuration - Use Your Loaf](https://useyourloaf.com/blog/swiftui-split-view-configuration/)
- [Using rich text in TextEditor - Create with Swift](https://www.createwithswift.com/using-rich-text-in-the-texteditor-with-swiftui/)
- [WWDC 2025 First Impressions - Fatbobman](https://fatbobman.com/en/posts/wwdc-2025-first-impressions/)
