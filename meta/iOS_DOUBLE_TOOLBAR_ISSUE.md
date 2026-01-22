# iOS Double Toolbar Issue

## TL;DR Summary

| Approach | Effort | Solves Double Toolbar | Correct Back Button Behavior |
|----------|--------|----------------------|------------------------------|
| **NavigationStack + NavigationBarHider (CURRENT)** | Medium | ✅ **WORKING** | ✅ **WORKING** |
| `NavigationBarHider` + `.toolbarRole(.automatic)` | Medium | ✅ Working | ❌ No |
| `.toolbarRole(.automatic)` alone | Low | ❌ No | N/A |
| Custom back button in DetailContentView | Medium | N/A | ❌ Creates double back buttons |
| Switch to `WindowGroup` (like Morning Pages) | High | ✅ | ✅ |

**Current solution (January 2026):** Use explicit `NavigationStack` on iOS with `navigationDestination(for:)`, `NavigationBarHider` to hide DocumentGroup's bar, and `List` without selection binding so `NavigationLink(value:)` works.

**Result:** ✅ Single toolbar, ✅ Back button correctly navigates within the project (not closing document).

---

## Problem Description

When opening a document on iOS in Manuscript, users see **two navigation bars/toolbars**:

1. **DocumentGroup's navigation bar** (outer)
   - Shows the document filename (e.g., "Untitled")
   - Has a back button that **closes the document entirely** (returns to document picker)
   - Has a dropdown menu for document actions

2. **NavigationSplitView's navigation bar** (inner)
   - Shows the current content title (e.g., "Test" for a character)
   - Has a back button that **navigates within the project** (correct behavior)
   - Has toolbar items like "Edit" button

### User Impact

- Confusing UX with redundant navigation bars
- The DocumentGroup back button behavior is problematic - users expect "back" to go back within the project, not close the document
- Wastes vertical screen space on iOS devices

### Root Cause

On iOS, `DocumentGroup` implicitly wraps content in a `NavigationStack`. When our content (`ManuscriptProjectView`) also contains a `NavigationSplitView`, this creates **nested navigation contexts**, each with their own navigation bar.

```
DocumentGroup (implicit NavigationStack on iOS)
  └── ManuscriptProjectView
        └── NavigationSplitView
              ├── Sidebar (ProjectSidebar)
              └── Detail (DetailContentView)
                    └── CharacterDetailView (with .navigationTitle)
```

This is a known architectural limitation of SwiftUI. As noted in the [Apple Developer Forums](https://developer.apple.com/forums/thread/727556), "NavigationSplitView is a top level navigation container and it's meant to be used without being wrapped in another navigation container."

---

## Current Implementation Status

**As of January 2026:**

### ✅ SOLVED: Both Double Toolbar AND Back Button Navigation

The solution involves three key components:

1. **Use explicit `NavigationStack` on iOS** (not NavigationSplitView)
2. **Use `NavigationBarHider`** to hide DocumentGroup's implicit navigation bar
3. **Use `List` without `selection:` binding on iOS** so NavigationLinks work

```swift
// ManuscriptProjectView.swift
@ViewBuilder
private var mainContent: some View {
    #if os(iOS)
    NavigationStack {
        ProjectSidebar(
            viewModel: viewModel,
            detailSelection: $detailSelection,
            // ... other bindings
        )
        .navigationDestination(for: DetailSelection.self) { selection in
            DetailContentView(
                viewModel: viewModel,
                selection: .constant(selection)
            )
        }
    }
    .background(NavigationBarHider())
    #else
    // macOS: Use NavigationSplitView as before
    NavigationSplitView {
        ProjectSidebar(...)
    } detail: {
        // ...
    }
    #endif
}
```

**Result:**
- ✅ Single toolbar displaying document title
- ✅ Back button navigates within the project (to sidebar)
- ✅ NavigationLink with `value:` pattern works naturally

### Why This Works

1. **Explicit NavigationStack** - We control our own navigation context
2. **NavigationBarHider** - Hides DocumentGroup's implicit navigation bar via UIKit
3. **`List` without selection** - On iOS, `List(selection:)` intercepts taps for selection instead of letting NavigationLinks navigate. Plain `List` lets NavigationLinks work.
4. **`navigationDestination(for:)`** - Tells SwiftUI how to handle DetailSelection navigation
5. **NavigationLink(value:)** in sidebar items - Pushes onto our NavigationStack naturally
6. **Back button** - Pops within our navigation flow, not closing the document

### Required Changes

#### 1. ProjectSidebar: Platform-specific List

```swift
// ProjectSidebar.swift
@ViewBuilder
private func sidebarList<Content: View>(content: Content, selection: Binding<DetailSelection?>) -> some View {
    #if os(iOS)
    // iOS: Don't use selection binding - NavigationLinks handle navigation
    List {
        content
    }
    .listStyle(.sidebar)
    #else
    // macOS: Use selection binding for NavigationSplitView
    List(selection: selection) {
        content
    }
    .listStyle(.sidebar)
    .navigationTitle(viewModel.document.title.isEmpty ? "Untitled" : viewModel.document.title)
    #endif
}
```

#### 2. DocumentItemView: NavigationLink on iOS

```swift
// DocumentItemView.swift
var body: some View {
    #if os(iOS)
    NavigationLink(value: DetailSelection.document(document)) {
        documentLabel
    }
    // ... modifiers
    #else
    documentLabel
        .tag(DetailSelection.document(document))
    // ... modifiers
    #endif
}
```

The `.tag()` approach works with `List(selection:)` binding (used by NavigationSplitView) but doesn't work with `navigationDestination(for:)`. NavigationLink(value:) is required for the navigation to actually push.

---

## Comparison: Morning Pages Architecture (No Double Toolbar)

The **Morning Pages** app in `literati-swift/morning-pages` does NOT have this issue because it uses a fundamentally different architecture:

### Morning Pages Setup (Works Correctly)
```swift
// morning_pagesApp.swift
@main
struct morning_pagesApp: App {
    var body: some Scene {
        #if os(iOS)
        WindowGroup {                          // ← Uses WindowGroup, NOT DocumentGroup
            ContentView()
        }
        #endif
    }
}

// ContentView.swift
struct ContentView: View {
    var body: some View {
        NavigationSplitView {                  // ← NavigationSplitView at top level
            SidebarView(...)
        } detail: {
            detailView
        }
    }
}
```

### Manuscript Setup (Has Double Toolbar)
```swift
// ManuscriptApp.swift
@main
struct ManuscriptApp: App {
    var body: some Scene {
        DocumentGroup(...) { file in           // ← DocumentGroup wraps in NavigationStack
            ManuscriptProjectView(...)
        }
    }
}

// ManuscriptProjectView.swift
struct ManuscriptProjectView: View {
    var body: some View {
        NavigationSplitView {                  // ← Second navigation container = DOUBLE TOOLBAR
            ProjectSidebar(...)
        } detail: {
            DetailContentView(...)
        }
    }
}
```

### Key Architectural Difference

| App | Scene Type | Navigation | Result |
|-----|------------|------------|--------|
| Morning Pages | `WindowGroup` | `NavigationSplitView` only | ✅ Single toolbar |
| Manuscript | `DocumentGroup` | Implicit `NavigationStack` + `NavigationSplitView` | ❌ Double toolbar |

### Why Morning Pages Works

1. **WindowGroup** doesn't add any implicit navigation container
2. **NavigationSplitView** is the only navigation context
3. The sidebar's back button correctly navigates within the split view
4. There's no document-level back button because there's no document browser

### Why Manuscript Has Issues

1. **DocumentGroup** on iOS implicitly wraps content in a `NavigationStack`
2. This gives the document browser's "close document" functionality
3. Our **NavigationSplitView** creates a second nested navigation context
4. iOS renders both navigation bars, causing the double toolbar

### Possible Migration Path

To achieve Morning Pages-like behavior while keeping document functionality:

**Option A: Custom Document Browser (Recommended for UX parity)**
```swift
#if os(iOS)
WindowGroup {
    CustomDocumentBrowserWrapper()
}
#else
DocumentGroup(newDocument: ManuscriptDocument()) { ... }
#endif
```

This would require implementing:
- Custom document picker UI
- Manual iCloud Drive integration
- File coordination for document access

**Option B: Accept DocumentGroup limitations, use `.toolbarRole(.automatic)`**

Keep DocumentGroup but apply the recommended fix to minimize the visual impact. The document-level back button will remain but won't appear as a duplicate.

---

## Approaches Tested

### Approach 1: `.toolbarRole(.editor)`

**Theory:** Using `.toolbarRole(.editor)` tells SwiftUI this is an editor-style document interface, which should adjust navigation behavior.

**Implementation:**
```swift
DocumentGroup(newDocument: ManuscriptDocument()) { file in
    ManuscriptProjectView(document: file.$document)
        .toolbarRole(.editor)
}
```

**Result:** ❌ Did not resolve the issue. Double toolbars still appeared.

---

### Approach 2: Hide navigation bar at app level

**Theory:** Using `.toolbar(.hidden, for: .navigationBar)` on the content view should hide the DocumentGroup's navigation bar.

**Implementation:**
```swift
DocumentGroup(newDocument: ManuscriptDocument()) { file in
    #if os(iOS)
    ManuscriptProjectView(document: file.$document)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    #endif
}
```

**Result:** ❌ This hides the **inner** NavigationSplitView bar, not the outer DocumentGroup bar. The modifier doesn't reach the DocumentGroup's implicit navigation container.

---

### Approach 3: Hide navigation bar on detail views

**Theory:** Apply `.toolbar(.hidden, for: .navigationBar)` to detail views to prevent their titles from activating a second bar.

**Implementation:**
```swift
// In DetailContentView
case .character(let character):
    CharacterDetailView(character: character, viewModel: viewModel)
        .toolbar(.hidden, for: .navigationBar)
```

**Result:** ⚠️ Partially worked - single toolbar shown, but this **removes the Edit button and title** from the detail view. Not acceptable UX.

---

### Approach 4: Remove `.navigationTitle()` from sidebar on iOS

**Theory:** The sidebar's `.navigationTitle()` might be activating DocumentGroup's navigation bar.

**Implementation:**
```swift
// In ProjectSidebar.swift
.listStyle(.sidebar)
#if os(macOS)
.navigationTitle(viewModel.document.title.isEmpty ? "Untitled" : viewModel.document.title)
#endif
```

**Result:** ❌ Did not resolve the issue. The DocumentGroup still shows its own title.

---

### Approach 5: Use `.navigationBarTitleDisplayMode(.inline)` on detail views

**Theory:** Using inline display mode might consolidate the navigation bars.

**Implementation:**
```swift
extension View {
    @ViewBuilder
    func applyiOSDetailViewModifiers() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
```

**Result:** ❌ Made titles more compact but did not resolve the double toolbar issue.

---

### Approach 6: UIViewControllerRepresentable wrapper to hide parent navigation bar ✅ WORKING

**Theory:** Use UIKit's `UINavigationController.setNavigationBarHidden()` to directly hide the DocumentGroup's navigation bar at the UIKit level.

**Implementation (Final Working Version):**
```swift
#if os(iOS)
struct NavigationBarHider: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = NavigationBarHiderController()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? NavigationBarHiderController)?.hideNavigationBar()
    }
}

class NavigationBarHiderController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hideNavigationBar()

        // Keep checking periodically to ensure it stays hidden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.hideNavigationBar()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.hideNavigationBar()
        }
    }

    func hideNavigationBar() {
        // Traverse up view controller hierarchy
        var current: UIViewController? = self
        while let vc = current {
            if let nav = vc.navigationController {
                nav.setNavigationBarHidden(true, animated: false)
                nav.navigationBar.isHidden = true
            }
            current = vc.parent
        }

        // Also try via responder chain
        var responder: UIResponder? = self
        while let r = responder {
            if let nav = r as? UINavigationController {
                nav.setNavigationBarHidden(true, animated: false)
                nav.navigationBar.isHidden = true
            }
            responder = r.next
        }
    }
}
#endif

// Usage in ManuscriptProjectView.swift:
NavigationSplitView { ... }
    #if os(iOS)
    .navigationSplitViewStyle(.balanced)
    .background(NavigationBarHider())
    #endif
```

**Result:** ✅ **WORKING** - Successfully hides the DocumentGroup's navigation bar, leaving only the NavigationSplitView's bar visible.

**Remaining Issue:** The back button in detail views still triggers document close instead of navigating within the project. This is a separate navigation hierarchy issue.

---

### Approach 7: Custom Back Button in DetailContentView

**Theory:** Hide the system back button and provide a custom one that sets `selection = nil` to navigate back to sidebar.

**Implementation:**
```swift
// In DetailContentView.swift
var body: some View {
    if let currentSelection = selection {
        detailContent(for: currentSelection)
            #if os(iOS)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        selection = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Project")
                        }
                    }
                }
            }
            #endif
    }
}
```

**Result:** ❌ Creates **double back buttons** - DocumentGroup's back button still appears alongside our custom button. The `.navigationBarBackButtonHidden(true)` only hides NavigationSplitView's back button, not DocumentGroup's.

---

### Approach 8: `.navigationBarBackButtonHidden(true)` at ManuscriptProjectView Level

**Theory:** Apply `.navigationBarBackButtonHidden(true)` at the root level to hide DocumentGroup's back button.

**Implementation:**
```swift
// In ManuscriptProjectView.swift
#if os(iOS)
.navigationSplitViewStyle(.balanced)
.navigationBarBackButtonHidden(true)
.background(NavigationBarHider())
.toolbarRole(.automatic)
#endif
```

**Result:** ❌ Does NOT hide DocumentGroup's back button. The modifier doesn't reach the DocumentGroup's implicit NavigationStack.

---

## Recommended Solutions (From Research)

### Solution A: `.toolbarRole(.automatic)` ⭐ RECOMMENDED

Based on [Daniel Saidi's blog](https://danielsaidi.com/blog/2022/12/10/removing-extra-back-button-in-documentgroup-navigation-bar), the recommended fix for the double back button issue is to apply `.toolbarRole(.automatic)` to the DocumentGroup content view.

**Implementation:**
```swift
extension View {
    @ViewBuilder
    func withAutomaticToolbarRole() -> some View {
        if #available(iOS 16.0, *) {
            self.toolbarRole(.automatic)
        } else {
            self
        }
    }
}

// Usage:
DocumentGroup(newDocument: ManuscriptDocument()) { file in
    ManuscriptProjectView(document: file.$document)
        .withAutomaticToolbarRole()
}
```

**Why it works:** The `.toolbarRole(.automatic)` modifier resets the toolbar behavior to default, preventing the duplicate back button that appeared starting with Xcode 16.

**Options that also work:**
- `.toolbarRole(.browser)`
- `.toolbarRole(.navigationStack)`

**Status:** 🧪 NOT YET TESTED in Manuscript

---

### Solution B: DismissingView for Custom Close Functionality

From [Nil Coalescing's blog](https://nilcoalescing.com/blog/AddingDoubleColumnNavigationToASwiftUIDocumentApp/), if you need to hide the system navigation bar completely but still allow dismissing back to the document browser:

**Implementation:**
```swift
#if os(iOS)
struct DismissingView: UIViewRepresentable {
    let dismiss: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        if dismiss {
            DispatchQueue.main.async {
                view.dismissViewController()
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if dismiss {
            DispatchQueue.main.async {
                uiView.dismissViewController()
            }
        }
    }
}

extension UIResponder {
    func dismissViewController() {
        guard let vc = self as? UIViewController else {
            self.next?.dismissViewController()
            return
        }
        vc.dismiss(animated: true)
    }
}

// Environment key for dismiss action
private struct DismissKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var dismissDocument: () -> Void {
        get { self[DismissKey.self] }
        set { self[DismissKey.self] = newValue }
    }
}

struct DismissModifier: ViewModifier {
    @State private var dismiss = false

    func body(content: Content) -> some View {
        content.background(
            DismissingView(dismiss: dismiss)
        )
        .environment(\.dismissDocument, {
            self.dismiss = true
        })
    }
}
#endif
```

**Usage - Add a close button to sidebar:**
```swift
struct CloseDocumentButton: View {
    @Environment(\.dismissDocument) var dismissDocument

    var body: some View {
        Button { dismissDocument() } label: {
            Label("Close", systemImage: "folder")
        }
    }
}

// In toolbar:
ToolbarItem(placement: .cancellationAction) {
    CloseDocumentButton()
}
```

**Status:** 🧪 NOT YET TESTED in Manuscript

---

## Known Platform Issues

### iOS 18.4.1 Bug (FIXED in iOS 18.5)

Per the [Apple Developer Forums](https://developer.apple.com/forums/thread/783239), iOS 18.4.1 had a bug where DocumentGroup contained the DocumentView twice, causing issues with alerts and toolbar duplication.

**Resolution:** This was fixed in iOS 18.5. No workarounds needed for iOS 18.5+.

### iOS 18 Toolbar Content Issues

Some developers reported on the [Apple Developer Forums](https://developer.apple.com/forums/thread/762513) that `.toolbarTitleMenu` or `ToolbarItem(placement: .principal)` content may not display correctly in iPadOS 18 when using `NavigationSplitView`.

**Filed Feedback:**
- FB14849205 - ToolbarTitleMenu not showing on iPadOS 18.x
- FB15164292 - Customizable toolbar items appear by default on iPadOS 18.1 beta 4

### iOS 26 / WWDC 2025 - Liquid Glass Design

According to [Hacking with Swift](https://www.hackingwithswift.com/articles/278/whats-new-in-swiftui-for-ios-26), iOS 26 introduces the "Liquid Glass" design language. Navigation stacks, tabs, inspectors, and toolbars become "glassy, more rounded, and transparent."

**Impact:** Building with Xcode 26 will automatically apply the new design. The double toolbar issue may manifest differently under Liquid Glass.

**New APIs in iOS 26:**
- Navigation subtitles
- Toolbar spacing control

**No specific fixes** for the DocumentGroup + NavigationSplitView nesting issue were announced at WWDC 2025.

### General DocumentGroup Limitations (As of December 2025)

Per [Michael Tsai's blog](https://mjtsai.com/blog/2025/08/05/swiftui-documentgroups-are-terribly-limited/):
- DocumentGroup still lacks programmatic document creation/opening
- SceneBuilder doesn't support conditional logic
- Platform-specific bugs persist (iOS save issues, visionOS navigation issues)

---

## Other Potential Approaches (Not Yet Tested)

### Approach 7: UINavigationBar.appearance() in app init

Configure navigation bar appearance globally to make DocumentGroup's bar transparent or hidden.

```swift
init() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
}
```

**Risk:** Would affect ALL navigation bars, including the ones we want to keep.

---

### Approach 8: Don't use NavigationSplitView on iOS

Replace `NavigationSplitView` with a custom implementation that doesn't create its own navigation context on iOS.

```swift
#if os(iOS)
// Custom split view without NavigationSplitView
TabView or custom sidebar implementation
#else
NavigationSplitView { ... }
#endif
```

**Risk:** Major refactor, would need to reimplement split view behavior.

---

### Approach 9: Don't use DocumentGroup on iOS

Use a custom document handling approach instead of `DocumentGroup` on iOS.

```swift
#if os(iOS)
WindowGroup {
    CustomDocumentBrowserView()
}
#else
DocumentGroup(newDocument: ManuscriptDocument()) { ... }
#endif
```

**Risk:** Major refactor, would need to reimplement document handling, iCloud integration, etc. Note: The [DocumentKit library](https://github.com/danielsaidi/DocumentKit) that previously helped with this has been archived since iOS 18 changed many things under the hood.

---

### Approach 10: Negative margin/overlay technique

Use negative margins or overlays to visually hide the DocumentGroup bar while keeping NavigationSplitView's bar.

```swift
ManuscriptProjectView(document: file.$document)
    .ignoresSafeArea(.all, edges: .top)
    .offset(y: -50)
    .padding(.top, 50)
```

**Risk:** Hacky, may cause layout issues, safe area problems.

---

## Files Modified

- `/Manuscript/Manuscript/ManuscriptApp.swift` - Main app entry point (no iOS-specific wrapper currently)
- `/Manuscript/Manuscript/Views/ManuscriptProjectView.swift` - Contains `.toolbar(.hidden, for: .navigationBar)` on sidebar
- `/Manuscript/Manuscript/Views/Components/ProjectSidebar.swift` - macOS-only navigationTitle
- `/Manuscript/Manuscript/Views/Components/Content/DetailContentView.swift` - Detail view container

---

## Recommended Next Steps

### Goal: Single Toolbar with Document Title, Back Button Goes to Sidebar

The user's requirement is clear:
- **One toolbar** showing the document title (not two)
- **Back button** should navigate within the project sidebar (not close the document)

### Priority Order

1. **Quick Fix: Test `.toolbarRole(.automatic)` (Solution A)**
   - Apply to `ManuscriptProjectView` in the DocumentGroup
   - May resolve the double back button specifically
   - Minimal code change
   - **Status:** 🧪 NOT YET TESTED

2. **If Solution A Insufficient: Combine with Navigation Bar Hiding**
   - Use `.toolbarRole(.automatic)` + `.toolbar(.hidden, for: .navigationBar)` on the outer level
   - Add custom "Close Document" button in the sidebar toolbar
   - Implement `DismissingView` (Solution B) for the close action

3. **If Still Not Working: Major Refactor to WindowGroup Architecture**
   - Follow Morning Pages pattern
   - Replace `DocumentGroup` with `WindowGroup` on iOS
   - Implement custom document picker using `UIDocumentPickerViewController`
   - Manual iCloud Drive integration
   - This gives full control but requires significant work

4. **Consider filing Apple Feedback:** Request better APIs for controlling DocumentGroup's navigation behavior on iOS, specifically:
   - Ability to opt-out of implicit NavigationStack wrapping
   - Better integration between DocumentGroup and NavigationSplitView

5. **Test on iOS 18.5+:** Ensure any fixes work with the iOS 18.4.1 bug fixes

6. **Prepare for iOS 26:** Test appearance under Liquid Glass design when Xcode 26 becomes available

---

## References

- [Apple Documentation: DocumentGroup](https://developer.apple.com/documentation/swiftui/documentgroup)
- [Apple Documentation: NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [Apple TN3154: Adopting SwiftUI navigation split view](https://developer.apple.com/documentation/technotes/tn3154-adopting-swiftui-navigation-split-view)
- [Daniel Saidi: Removing extra back button in DocumentGroup](https://danielsaidi.com/blog/2022/12/10/removing-extra-back-button-in-documentgroup-navigation-bar)
- [Nil Coalescing: Double column navigation in a SwiftUI document app](https://nilcoalescing.com/blog/AddingDoubleColumnNavigationToASwiftUIDocumentApp/)
- [Apple Developer Forums: iOS 18.4.1 DocumentGroup bug](https://developer.apple.com/forums/thread/783239)
- [Apple Developer Forums: iOS 18 Toolbar issues](https://developer.apple.com/forums/thread/762513)
- [Hacking with Swift: What's new in SwiftUI for iOS 26](https://www.hackingwithswift.com/articles/278/whats-new-in-swiftui-for-ios-26)
- [Michael Tsai: SwiftUI DocumentGroups Are Terribly Limited](https://mjtsai.com/blog/2025/08/05/swiftui-documentgroups-are-terribly-limited/)
- [GitHub: DocumentKit (archived)](https://github.com/danielsaidi/DocumentKit)
