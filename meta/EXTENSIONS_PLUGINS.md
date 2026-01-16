# Extensions and Plugins Architecture

This document analyzes different approaches for implementing extensions or plugins in Manuscript, a native iOS/macOS writing application built with SwiftUI.

## Table of Contents

1. [Overview](#overview)
2. [Approach Comparison Matrix](#approach-comparison-matrix)
3. [Detailed Analysis](#detailed-analysis)
   - [Native App Extensions](#1-native-app-extensions)
   - [Protocol-Based Plugin System](#2-protocol-based-plugin-system)
   - [App Intents & Shortcuts](#3-app-intents--shortcuts)
   - [AppleScript/JavaScript for Automation (macOS)](#4-applescriptjavascript-for-automation-macos)
   - [XPC Services](#5-xpc-services)
   - [Dynamic Library Loading](#6-dynamic-library-loading)
   - [WebView-Based Extensions](#7-webview-based-extensions)
   - [Document Actions/Middleware](#8-document-actionsmiddleware)
4. [Recommendations for Manuscript](#recommendations-for-manuscript)
5. [Implementation Roadmap](#implementation-roadmap)

---

## Overview

Manuscript's current architecture (MVVM + Actor-based services) provides several natural extension points:

- **Services Layer**: Actor-based services like `APIService`, `TextGenerationService`
- **Import Pipeline**: Modular importers following `ScrivenerImporter` pattern
- **Document Model**: Extensible metadata in `project.json`
- **Observable ViewModels**: Reactive state management

The key question is: **How should third parties extend Manuscript's functionality?**

### Goals for an Extension System

| Priority | Goal |
|----------|------|
| **High** | Security - Sandboxed, no unauthorized data access |
| **High** | Stability - Extensions can't crash the main app |
| **High** | User Control - Easy to enable/disable/remove |
| **Medium** | Discoverability - Users can find useful extensions |
| **Medium** | Developer Experience - Easy to build extensions |
| **Low** | Performance - Minimal overhead for unused extensions |

---

## Approach Comparison Matrix

| Approach | Security | Isolation | Cross-Platform | Dev Complexity | User Install | Capabilities |
|----------|----------|-----------|----------------|----------------|--------------|--------------|
| Native App Extensions | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Limited |
| Protocol-Based Plugins | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | Full |
| App Intents/Shortcuts | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Limited |
| AppleScript (macOS) | ⭐⭐⭐ | ⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Medium |
| XPC Services | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ | Full |
| Dynamic Libraries | ⭐ | ⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐ | Full |
| WebView Extensions | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Medium |
| Document Middleware | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Focused |

---

## Detailed Analysis

### 1. Native App Extensions

Apple's official extension mechanism for inter-app functionality.

#### Relevant Extension Types

| Extension Type | Use Case for Manuscript |
|----------------|------------------------|
| **Share Extension** | Export documents to other apps |
| **Action Extension** | Process selected text |
| **File Provider** | Expose documents to Files app |
| **Quick Look Preview** | Preview `.manuscript` files in Finder |
| **Spotlight Importer** | Index document content for search |

#### Implementation Example

```swift
// Share Extension - ManuscriptShare/ShareViewController.swift
class ShareViewController: SLComposeServiceViewController {
    override func isContentValid() -> Bool {
        return contentText?.isEmpty == false
    }

    override func didSelectPost() {
        guard let text = contentText else { return }

        // Access shared App Group container
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.manuscript")

        // Save to shared location for main app to import
        let importURL = groupURL?.appendingPathComponent("import-queue")
        // ... save text

        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
```

#### Pros

- ✅ **Apple-sanctioned** - Full App Store compliance
- ✅ **Strong sandboxing** - Each extension runs in own process
- ✅ **System integration** - Appears in Share sheets, Finder, Spotlight
- ✅ **No external dependencies** - Built into Apple platforms
- ✅ **User trust** - Familiar extension installation via App Store

#### Cons

- ❌ **Limited scope** - Only predefined extension types
- ❌ **Separate binaries** - Each extension is a separate target
- ❌ **Communication overhead** - IPC required for data exchange
- ❌ **Limited UI** - Constrained presentation contexts
- ❌ **Platform differences** - Some extensions macOS-only (Quick Look)

#### Best For

System-level integration: sharing, previewing, file access, Spotlight indexing.

---

### 2. Protocol-Based Plugin System

Internal plugin architecture using Swift protocols and optional dynamic loading.

#### Architecture

```swift
// Plugin Protocol Definition
public protocol ManuscriptPlugin: AnyObject {
    static var identifier: String { get }
    static var displayName: String { get }
    static var version: String { get }

    init()

    func activate(context: PluginContext) async throws
    func deactivate() async
}

// Plugin Context - What plugins can access
public struct PluginContext {
    let documentAccess: DocumentAccessProtocol
    let uiExtension: UIExtensionProtocol
    let storage: PluginStorageProtocol
    let logger: LoggerProtocol
}

// Specific Plugin Types
public protocol ImporterPlugin: ManuscriptPlugin {
    var supportedFileTypes: [UTType] { get }
    func canImport(url: URL) -> Bool
    func importDocument(from url: URL, progress: ProgressReporter) async throws -> ManuscriptDocument
}

public protocol ExporterPlugin: ManuscriptPlugin {
    var exportFormats: [ExportFormat] { get }
    func export(document: ManuscriptDocument, format: ExportFormat, to url: URL) async throws
}

public protocol TextProcessorPlugin: ManuscriptPlugin {
    var processorName: String { get }
    func process(text: String, options: [String: Any]) async throws -> String
}
```

#### Plugin Manager Implementation

```swift
@MainActor
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published private(set) var loadedPlugins: [String: any ManuscriptPlugin] = [:]
    @Published private(set) var availablePlugins: [PluginDescriptor] = []

    private let pluginDirectory: URL

    func discoverPlugins() async {
        // Scan plugin directory
        let contents = try? FileManager.default.contentsOfDirectory(
            at: pluginDirectory,
            includingPropertiesForKeys: nil
        )

        for url in contents ?? [] where url.pathExtension == "manuscriptplugin" {
            if let descriptor = try? loadDescriptor(from: url) {
                availablePlugins.append(descriptor)
            }
        }
    }

    func loadPlugin(_ identifier: String) async throws {
        guard let descriptor = availablePlugins.first(where: { $0.identifier == identifier }) else {
            throw PluginError.notFound
        }

        // Load and instantiate plugin
        let plugin = try await instantiatePlugin(from: descriptor)
        let context = createContext(for: plugin)
        try await plugin.activate(context: context)
        loadedPlugins[identifier] = plugin
    }

    func unloadPlugin(_ identifier: String) async {
        guard let plugin = loadedPlugins[identifier] else { return }
        await plugin.deactivate()
        loadedPlugins.removeValue(forKey: identifier)
    }
}
```

#### Pros

- ✅ **Full control** - Define exactly what plugins can do
- ✅ **Type safety** - Swift protocols enforce correct implementation
- ✅ **Deep integration** - Plugins can extend any part of the app
- ✅ **Cross-platform** - Same plugin works on iOS and macOS
- ✅ **Rich capabilities** - No arbitrary limitations

#### Cons

- ❌ **Security risk** - Plugins run in-process with full access
- ❌ **Stability risk** - Plugin crash can crash the app
- ❌ **Distribution** - No standard mechanism (no App Store)
- ❌ **Sandboxing conflicts** - May violate App Store sandbox rules
- ❌ **Maintenance burden** - Must maintain plugin API stability

#### Best For

Power users, enterprise deployments, or non-App Store distribution.

---

### 3. App Intents & Shortcuts

Modern Apple approach for exposing app functionality to Shortcuts and Siri.

#### Implementation

```swift
import AppIntents

// Define an App Intent
struct CreateDocumentIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Document"
    static var description = IntentDescription("Creates a new document in Manuscript")

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Content", default: "")
    var content: String

    @Parameter(title: "Folder")
    var folder: FolderEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Create document \(\.$title)") {
            \.$content
            \.$folder
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<DocumentEntity> {
        let document = try await DocumentService.shared.createDocument(
            title: title,
            content: content,
            in: folder?.id
        )
        return .result(value: DocumentEntity(document))
    }
}

// Define App Entity for documents
struct DocumentEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Document")
    static var defaultQuery = DocumentQuery()

    var id: UUID
    var title: String
    var wordCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(wordCount) words")
    }
}

// Query for finding documents
struct DocumentQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [DocumentEntity] {
        try await DocumentService.shared.documents(for: identifiers)
            .map(DocumentEntity.init)
    }

    func suggestedEntities() async throws -> [DocumentEntity] {
        try await DocumentService.shared.recentDocuments()
            .map(DocumentEntity.init)
    }
}

// App Shortcuts Provider
struct ManuscriptShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateDocumentIntent(),
            phrases: [
                "Create a document in \(.applicationName)",
                "New \(.applicationName) document"
            ],
            shortTitle: "Create Document",
            systemImageName: "doc.badge.plus"
        )

        AppShortcut(
            intent: GetWordCountIntent(),
            phrases: ["Word count in \(.applicationName)"],
            shortTitle: "Word Count",
            systemImageName: "number"
        )
    }
}
```

#### Supported Actions for Manuscript

| Intent | Description |
|--------|-------------|
| `CreateDocumentIntent` | Create new document |
| `GetWordCountIntent` | Get word/character count |
| `ExportDocumentIntent` | Export to PDF/DOCX/etc |
| `SearchDocumentsIntent` | Find documents by query |
| `GenerateTextIntent` | AI text generation |
| `SetLabelIntent` | Assign label to document |
| `CompileProjectIntent` | Compile manuscript |

#### Pros

- ✅ **Official Apple API** - Full platform support
- ✅ **Siri integration** - Voice commands for free
- ✅ **Shortcuts app** - Users build custom workflows
- ✅ **Cross-app automation** - Chain with other apps
- ✅ **No code for users** - Visual automation builder
- ✅ **Sandboxed** - Runs through system framework

#### Cons

- ❌ **Action-based only** - Can't modify UI or add features
- ❌ **Limited data types** - Must fit Apple's entity model
- ❌ **iOS 16+/macOS 13+** - Requires recent OS versions
- ❌ **Discovery** - Users must know to look in Shortcuts

#### Best For

Automation, inter-app workflows, voice control, accessibility.

---

### 4. AppleScript/JavaScript for Automation (macOS)

Classic macOS scripting via Apple Events.

#### Implementation

```swift
// Define scriptable classes in SDEF file
// Manuscript.sdef
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE dictionary SYSTEM "file://localhost/System/Library/DTDs/sdef.dtd">
<dictionary title="Manuscript Terminology">
    <suite name="Standard Suite" code="????" description="Common classes and commands">
        <command name="open" code="aevtodoc" description="Open a document">
            <direct-parameter description="The file(s) to open" type="file"/>
        </command>
    </suite>

    <suite name="Manuscript Suite" code="Mnsc" description="Manuscript-specific classes">
        <class name="document" code="docu" description="A Manuscript document">
            <property name="name" code="pnam" type="text" access="rw"/>
            <property name="word count" code="MnWC" type="integer" access="r"/>
            <property name="content" code="MnCt" type="text" access="rw"/>
            <element type="folder"/>
        </class>

        <class name="folder" code="MnFl" description="A folder in a document">
            <property name="name" code="pnam" type="text" access="rw"/>
            <element type="document item"/>
            <element type="folder"/>
        </class>

        <class name="document item" code="MnDI" description="A document item">
            <property name="title" code="MnTl" type="text" access="rw"/>
            <property name="content" code="MnCt" type="text" access="rw"/>
            <property name="label" code="MnLb" type="text" access="rw"/>
            <property name="status" code="MnSt" type="text" access="rw"/>
        </class>

        <command name="compile" code="MnCmpl" description="Compile the manuscript">
            <direct-parameter description="The document to compile" type="document"/>
            <parameter name="to" code="MnTo" type="file" description="Output file"/>
            <parameter name="format" code="MnFm" type="text" description="Output format"/>
        </command>

        <command name="generate text" code="MnGnTx" description="Generate text with AI">
            <parameter name="prompt" code="MnPr" type="text" description="Generation prompt"/>
            <result type="text"/>
        </command>
    </suite>
</dictionary>
```

```swift
// Swift implementation for scriptable objects
@objc(ManuscriptApplication)
class ManuscriptApplication: NSApplication {
    @objc var documents: [ScriptableDocument] {
        // Return open documents
    }
}

@objc(ScriptableDocument)
class ScriptableDocument: NSObject {
    @objc var name: String
    @objc var wordCount: Int { content.wordCount }
    @objc var content: String
    @objc var folders: [ScriptableFolder]

    @objc func compile(to url: URL, format: String) {
        // Compile implementation
    }
}
```

#### Example AppleScript Usage

```applescript
tell application "Manuscript"
    set myDoc to open "~/Documents/Novel.manuscript"

    -- Get word count
    set totalWords to word count of myDoc

    -- Modify content
    tell folder "Draft" of myDoc
        set content of document item "Chapter 1" to "It was a dark and stormy night..."
    end tell

    -- Compile to PDF
    compile myDoc to "~/Desktop/Novel.pdf" format "pdf"

    -- AI generation
    set newText to generate text with prompt "Continue the story..."
end tell
```

#### Pros

- ✅ **Powerful automation** - Full scriptable access
- ✅ **User-created workflows** - No developer needed
- ✅ **Integration with other apps** - Apple Events ecosystem
- ✅ **Familiar to power users** - Long macOS tradition
- ✅ **IDE support** - Script Editor, debugger included

#### Cons

- ❌ **macOS only** - No iOS equivalent
- ❌ **Complex implementation** - SDEF files, NSScriptCommand
- ❌ **Sandboxing issues** - Limited in sandboxed apps
- ❌ **Declining usage** - Shortcuts is the modern replacement
- ❌ **Security concerns** - Scripts can do almost anything

#### Best For

macOS power users, integration with traditional Mac workflows.

---

### 5. XPC Services

Out-of-process extensions with strong isolation.

#### Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Manuscript.app                      │
│  ┌─────────────────────────────────────────────┐    │
│  │              Main Process                    │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────┐ │    │
│  │  │  Views  │  │ViewModels│  │  Services   │ │    │
│  │  └─────────┘  └─────────┘  └──────┬──────┘ │    │
│  │                                    │        │    │
│  │               ┌────────────────────▼───┐   │    │
│  │               │    XPC Connection Mgr   │   │    │
│  │               └────────────────────────┘   │    │
│  └─────────────────────────┬───────────────────┘    │
│                            │ XPC                    │
│  ┌─────────────────────────▼───────────────────┐    │
│  │           XPC Service Bundle                 │    │
│  │  ┌──────────────────────────────────────┐   │    │
│  │  │    Plugin Host (Sandboxed Process)    │   │    │
│  │  │  ┌────────┐ ┌────────┐ ┌────────┐   │   │    │
│  │  │  │Plugin A│ │Plugin B│ │Plugin C│   │   │    │
│  │  │  └────────┘ └────────┘ └────────┘   │   │    │
│  │  └──────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

#### Implementation

```swift
// XPC Protocol Definition
@objc protocol ManuscriptXPCProtocol {
    func processText(
        _ text: String,
        options: [String: Any],
        reply: @escaping (String?, Error?) -> Void
    )

    func importDocument(
        at url: URL,
        reply: @escaping (Data?, Error?) -> Void
    )

    func exportDocument(
        _ documentData: Data,
        format: String,
        reply: @escaping (Data?, Error?) -> Void
    )
}

// XPC Service Implementation
class ManuscriptXPCService: NSObject, ManuscriptXPCProtocol {
    func processText(
        _ text: String,
        options: [String: Any],
        reply: @escaping (String?, Error?) -> Void
    ) {
        // Process in isolated environment
        let processed = PluginEngine.shared.process(text, options: options)
        reply(processed, nil)
    }
}

// Main App Connection Manager
class XPCConnectionManager {
    private var connection: NSXPCConnection?

    func connect() {
        connection = NSXPCConnection(serviceName: "com.manuscript.xpc-plugins")
        connection?.remoteObjectInterface = NSXPCInterface(with: ManuscriptXPCProtocol.self)
        connection?.resume()
    }

    func processText(_ text: String, options: [String: Any]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let proxy = connection?.remoteObjectProxyWithErrorHandler { error in
                continuation.resume(throwing: error)
            } as? ManuscriptXPCProtocol

            proxy?.processText(text, options: options) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result ?? "")
                }
            }
        }
    }
}
```

#### Pros

- ✅ **Process isolation** - Plugin crash doesn't affect main app
- ✅ **Strong sandboxing** - Separate entitlements per service
- ✅ **Security** - Limited communication surface
- ✅ **Resource limits** - OS can manage memory/CPU per process
- ✅ **App Store compatible** - Approved mechanism

#### Cons

- ❌ **Complex architecture** - Multiple processes, IPC overhead
- ❌ **Limited data transfer** - Must serialize across process boundary
- ❌ **No UI** - XPC services are headless
- ❌ **Build complexity** - Separate targets, signing, entitlements
- ❌ **Latency** - IPC adds overhead to every call

#### Best For

Heavy processing tasks, untrusted code execution, stability-critical features.

---

### 6. Dynamic Library Loading

Loading compiled Swift/Objective-C code at runtime.

#### Implementation

```swift
// Plugin Bundle Structure
// MyPlugin.bundle/
// ├── Contents/
// │   ├── Info.plist
// │   ├── MacOS/
// │   │   └── MyPlugin (Mach-O executable)
// │   └── Resources/
// │       └── plugin.json

// Plugin Loader
class DynamicPluginLoader {
    func loadPlugin(at url: URL) throws -> any ManuscriptPlugin {
        // Load the bundle
        guard let bundle = Bundle(url: url) else {
            throw PluginError.invalidBundle
        }

        guard bundle.load() else {
            throw PluginError.loadFailed
        }

        // Get principal class
        guard let principalClass = bundle.principalClass as? ManuscriptPlugin.Type else {
            throw PluginError.invalidPluginClass
        }

        // Instantiate
        return principalClass.init()
    }
}

// Plugin Principal Class
@objc(MyPlugin)
public class MyPlugin: NSObject, ManuscriptPlugin {
    public static var identifier = "com.example.myplugin"
    public static var displayName = "My Plugin"
    public static var version = "1.0.0"

    public required override init() {
        super.init()
    }

    public func activate(context: PluginContext) async throws {
        // Setup plugin
    }

    public func deactivate() async {
        // Cleanup
    }
}
```

#### Pros

- ✅ **Full native performance** - Compiled code
- ✅ **Complete access** - Can use all Swift/ObjC APIs
- ✅ **Flexible** - Plugins can do anything the app can
- ✅ **Familiar model** - Similar to macOS bundles/plug-ins

#### Cons

- ❌ **Security nightmare** - Arbitrary code execution
- ❌ **ABI stability** - Must match Swift runtime version
- ❌ **App Store rejection** - Violates code signing requirements
- ❌ **Crashes propagate** - Plugin crash = app crash
- ❌ **Platform complexity** - Different on iOS vs macOS
- ❌ **Code signing** - Complex entitlements required

#### Best For

Internal/enterprise use only, NOT suitable for public distribution.

---

### 7. WebView-Based Extensions

JavaScript extensions running in WKWebView sandbox.

#### Architecture

```swift
// Extension Manifest (extension.json)
{
    "name": "Word Frequency Analyzer",
    "version": "1.0.0",
    "description": "Analyzes word frequency in your document",
    "main": "index.html",
    "permissions": ["document.read"],
    "ui": {
        "type": "sidebar",
        "width": 300
    }
}

// Extension Bridge
class ExtensionBridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    let documentAccess: DocumentAccessProtocol

    func setupBridge() {
        let config = WKWebViewConfiguration()

        // Inject Manuscript API
        let apiScript = WKUserScript(
            source: manuscriptAPISource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(apiScript)

        // Register message handlers
        config.userContentController.add(self, name: "manuscript")

        webView = WKWebView(frame: .zero, configuration: config)
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "getDocument":
            let doc = documentAccess.currentDocument
            sendToWebView(["type": "document", "data": doc.toJSON()])

        case "setContent":
            if let content = body["content"] as? String {
                documentAccess.setContent(content)
            }

        default:
            break
        }
    }
}

// JavaScript API (injected into WebView)
let manuscriptAPISource = """
window.Manuscript = {
    async getDocument() {
        return new Promise((resolve) => {
            window._callbacks = window._callbacks || {};
            const id = Date.now();
            window._callbacks[id] = resolve;
            window.webkit.messageHandlers.manuscript.postMessage({
                action: 'getDocument',
                callbackId: id
            });
        });
    },

    async setContent(content) {
        window.webkit.messageHandlers.manuscript.postMessage({
            action: 'setContent',
            content: content
        });
    },

    async getSelection() { /* ... */ },
    async insertText(text) { /* ... */ },

    ui: {
        showNotification(message) { /* ... */ },
        showProgress(percent) { /* ... */ }
    }
};
"""
```

#### Example Extension (HTML/JS)

```html
<!-- index.html -->
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: -apple-system; padding: 16px; }
        .word { display: flex; justify-content: space-between; }
    </style>
</head>
<body>
    <h2>Word Frequency</h2>
    <div id="results"></div>

    <script>
        async function analyze() {
            const doc = await Manuscript.getDocument();
            const words = doc.content.toLowerCase().match(/\b\w+\b/g) || [];

            const freq = {};
            words.forEach(w => freq[w] = (freq[w] || 0) + 1);

            const sorted = Object.entries(freq)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 20);

            document.getElementById('results').innerHTML = sorted
                .map(([word, count]) =>
                    `<div class="word"><span>${word}</span><span>${count}</span></div>`
                ).join('');
        }

        analyze();
    </script>
</body>
</html>
```

#### Pros

- ✅ **Strong sandboxing** - JavaScript runs in WKWebView sandbox
- ✅ **Web technologies** - HTML/CSS/JS familiar to many developers
- ✅ **Easy distribution** - Just HTML/JS files
- ✅ **Cross-platform** - Same extension works iOS and macOS
- ✅ **UI included** - Extensions can have rich interfaces
- ✅ **Hot reload** - No compilation needed

#### Cons

- ❌ **Performance** - JavaScript slower than native
- ❌ **Limited API** - Only exposed bridge functions available
- ❌ **UI consistency** - Web UI may not match native look
- ❌ **Memory overhead** - Each WebView consumes resources
- ❌ **Bridge complexity** - Must maintain JS<->Swift API

#### Best For

UI-heavy extensions, third-party development, quick prototyping.

---

### 8. Document Actions/Middleware

Hooks into the document save/load/export pipeline.

#### Implementation

```swift
// Action Protocol
protocol DocumentAction: Identifiable {
    var id: String { get }
    var name: String { get }
    var trigger: ActionTrigger { get }

    func execute(document: ManuscriptDocument, context: ActionContext) async throws -> ManuscriptDocument
}

enum ActionTrigger {
    case beforeSave
    case afterSave
    case beforeExport(format: ExportFormat)
    case afterExport(format: ExportFormat)
    case onOpen
    case manual
}

// Action Manager
actor DocumentActionManager {
    private var registeredActions: [DocumentAction] = []

    func register(_ action: DocumentAction) {
        registeredActions.append(action)
    }

    func execute(trigger: ActionTrigger, document: ManuscriptDocument) async throws -> ManuscriptDocument {
        var result = document

        for action in registeredActions where action.trigger == trigger {
            result = try await action.execute(document: result, context: .init())
        }

        return result
    }
}

// Built-in Actions
struct AutoBackupAction: DocumentAction {
    let id = "com.manuscript.auto-backup"
    let name = "Auto Backup"
    let trigger = ActionTrigger.afterSave

    func execute(document: ManuscriptDocument, context: ActionContext) async throws -> ManuscriptDocument {
        let backupURL = /* create backup */
        try document.write(to: backupURL)
        return document
    }
}

struct WordCountLogAction: DocumentAction {
    let id = "com.manuscript.word-count-log"
    let name = "Log Word Count"
    let trigger = ActionTrigger.afterSave

    func execute(document: ManuscriptDocument, context: ActionContext) async throws -> ManuscriptDocument {
        let count = document.totalWordCount
        Logger.shared.info("Document saved with \(count) words")
        return document
    }
}

// User-Defined Script Action
struct ScriptAction: DocumentAction {
    let id: String
    let name: String
    let trigger: ActionTrigger
    let scriptURL: URL

    func execute(document: ManuscriptDocument, context: ActionContext) async throws -> ManuscriptDocument {
        // Run script via NSUserScriptTask (macOS) or JavaScriptCore
        let task = try NSUserScriptTask(url: scriptURL)
        try await task.execute()
        return document
    }
}
```

#### Pros

- ✅ **Focused scope** - Clear, limited functionality
- ✅ **Pipeline integration** - Natural fit for document workflows
- ✅ **Easy to understand** - Simple input/output model
- ✅ **Composable** - Chain multiple actions
- ✅ **Safe default** - Can't break unrelated features

#### Cons

- ❌ **Limited scope** - Only document-related operations
- ❌ **No UI** - Actions are headless
- ❌ **Timing constraints** - Must complete quickly for save operations
- ❌ **Error handling** - Failed action could block save

#### Best For

Automated workflows, document processing, export customization.

---

## Recommendations for Manuscript

Based on Manuscript's architecture and goals, here's a prioritized implementation plan:

### Phase 1: Foundation (Recommended First)

#### 1. App Intents & Shortcuts ⭐⭐⭐⭐⭐

**Why**: Maximum value with minimal complexity. Provides automation without security risks.

**Implement these intents:**
- `CreateDocumentIntent` - Create new document
- `GetDocumentIntent` - Retrieve document by title
- `GetWordCountIntent` - Word/character statistics
- `SetLabelIntent` / `SetStatusIntent` - Update metadata
- `ExportDocumentIntent` - Export to various formats
- `SearchDocumentsIntent` - Find documents
- `GenerateTextIntent` - AI text generation
- `CompileProjectIntent` - Compile manuscript

**Effort**: Medium (2-3 weeks)
**Value**: High - works with Siri, Shortcuts, Focus modes

#### 2. Native App Extensions ⭐⭐⭐⭐

**Why**: Required for proper system integration.

**Implement:**
- Quick Look Preview Extension (macOS) - Preview `.manuscript` files
- Share Extension - Import text from other apps
- Spotlight Importer - Index document content
- File Provider Extension - Expose to Files app (iOS)

**Effort**: Medium (1-2 weeks per extension)
**Value**: High - professional platform integration

### Phase 2: Advanced Extensibility

#### 3. Document Middleware/Actions ⭐⭐⭐⭐

**Why**: Enables workflow automation without full plugin complexity.

**Implement:**
- Action protocol for document lifecycle hooks
- Built-in actions (auto-backup, statistics logging)
- User script actions (JavaScript via JavaScriptCore)
- Export format customization

**Effort**: Low-Medium (1-2 weeks)
**Value**: Medium-High - power user workflows

#### 4. WebView Extensions ⭐⭐⭐

**Why**: Enables third-party extensions with good security model.

**Implement:**
- Extension manifest format
- JavaScript bridge API
- Sidebar/panel UI integration
- Extension management UI

**Effort**: High (4-6 weeks)
**Value**: Medium - enables ecosystem

### Phase 3: Power Features (Optional)

#### 5. AppleScript Support (macOS only) ⭐⭐⭐

**Why**: Expected by Mac power users.

**Implement:**
- SDEF dictionary for document model
- Scriptable document/folder/item classes
- Basic commands (open, compile, export)

**Effort**: Medium (2-3 weeks)
**Value**: Medium - macOS power users only

#### 6. XPC Plugin Host ⭐⭐

**Why**: Maximum security for untrusted extensions.

**Implement only if:**
- Significant third-party plugin ecosystem develops
- Enterprise customers require isolated execution

**Effort**: Very High (6-8 weeks)
**Value**: Low initially - complex for little benefit until ecosystem exists

### Not Recommended

❌ **Dynamic Library Loading** - Security risk, App Store incompatible
❌ **Protocol-Based Plugins (in-process)** - Stability risk, sandbox violations

---

## Implementation Roadmap

```
┌─────────────────────────────────────────────────────────────────┐
│                    Extension Roadmap                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Phase 1: Foundation                                             │
│  ├── App Intents (Shortcuts/Siri)                               │
│  │   ├── Document CRUD intents                                  │
│  │   ├── Search & query intents                                 │
│  │   ├── Export intents                                         │
│  │   └── AI generation intents                                  │
│  │                                                               │
│  └── Native Extensions                                           │
│      ├── Quick Look Preview (macOS)                             │
│      ├── Share Extension (iOS/macOS)                            │
│      ├── Spotlight Importer                                     │
│      └── File Provider (iOS)                                    │
│                                                                  │
│  Phase 2: Workflows                                              │
│  ├── Document Actions/Middleware                                │
│  │   ├── Lifecycle hooks (save/load/export)                    │
│  │   ├── Built-in actions                                       │
│  │   └── User script actions                                    │
│  │                                                               │
│  └── WebView Extensions                                          │
│      ├── Extension manifest format                              │
│      ├── JavaScript bridge API                                  │
│      ├── UI integration (sidebar/panel)                         │
│      └── Extension marketplace UI                               │
│                                                                  │
│  Phase 3: Platform (Optional)                                    │
│  ├── AppleScript Support (macOS)                                │
│  └── XPC Plugin Host (if needed)                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Appendix: Security Considerations

### Sandboxing Matrix

| Approach | Sandbox Compatible | Data Access | Network Access |
|----------|-------------------|-------------|----------------|
| App Intents | ✅ Full | Explicit only | App-controlled |
| Native Extensions | ✅ Full | App Group only | Restricted |
| WebView Extensions | ✅ Full | Bridge only | CSP-controlled |
| Document Actions | ✅ Full | Document only | None |
| AppleScript | ⚠️ Limited | Full (macOS) | Unrestricted |
| XPC Services | ✅ Full | Explicit IPC | Per-service |
| Dynamic Libraries | ❌ No | Full | Unrestricted |

### Recommended Security Model

1. **Principle of Least Privilege** - Extensions only get APIs they explicitly request
2. **User Consent** - Prompt before granting sensitive permissions
3. **Sandboxed Execution** - All third-party code runs isolated
4. **Revocable Access** - Users can disable extensions at any time
5. **Signed Extensions** - Require code signing for WebView extensions
6. **Audit Logging** - Log extension API usage for debugging

---

## References

- [Apple App Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)
- [App Intents Framework](https://developer.apple.com/documentation/appintents)
- [WKWebView JavaScript Bridge](https://developer.apple.com/documentation/webkit/wkscriptmessagehandler)
- [XPC Services](https://developer.apple.com/documentation/xpc)
- [AppleScript Overview](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptX/)
