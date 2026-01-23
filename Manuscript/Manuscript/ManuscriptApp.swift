//
//  ManuscriptApp.swift
//  Manuscript
//
//  Created by Jonas Dalesjö on 2025-02-16.
//

import SwiftUI
import UserNotifications
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

// MARK: - ManuscriptDocument Template Extension

extension ManuscriptDocument {
    /// Creates a new ManuscriptDocument from a BookTemplate
    static func fromTemplate(_ template: BookTemplate, title: String = "", author: String = "") -> ManuscriptDocument {
        var document = ManuscriptDocument()
        document.title = title
        document.author = author
        document.templateId = template.id

        // Apply the template structure to the root folder
        for subfolder in template.structure.subfolders {
            var newFolder = ManuscriptFolder(title: subfolder.title)
            populateFolder(&newFolder, from: subfolder)
            document.rootFolder.subfolders.append(newFolder)
        }

        return document
    }

    private static func populateFolder(_ folder: inout ManuscriptFolder, from template: FolderTemplate) {
        // Add documents
        var documents: [ManuscriptDocument.Document] = []
        for docTemplate in template.documents {
            let document = ManuscriptDocument.Document(
                title: docTemplate.title,
                synopsis: docTemplate.synopsis,
                notes: docTemplate.notes,
                content: docTemplate.content,
                order: docTemplate.order
            )
            documents.append(document)
        }
        folder.documents = documents

        // Add subfolders recursively
        var subfolders: [ManuscriptFolder] = []
        for subfolder in template.subfolders {
            var childFolder = ManuscriptFolder(title: subfolder.title)
            populateFolder(&childFolder, from: subfolder)
            subfolders.append(childFolder)
        }
        folder.subfolders = subfolders
    }
}

// MARK: - Find Menu Commands (macOS)

#if os(macOS)
/// Menu commands for Find functionality in the Edit menu
struct FindMenuCommands: View {
    @FocusedValue(\.findActions) var findActions

    var body: some View {
        Button("Find...") {
            findActions?.showFind()
        }
        .keyboardShortcut("f", modifiers: .command)
        .disabled(findActions == nil)

        Button("Find and Replace...") {
            findActions?.showFindAndReplace()
        }
        .keyboardShortcut("f", modifiers: [.command, .option])
        .disabled(findActions == nil)

        Divider()

        Button("Find Next") {
            findActions?.findNext()
        }
        .keyboardShortcut("g", modifiers: .command)
        .disabled(findActions == nil)

        Button("Find Previous") {
            findActions?.findPrevious()
        }
        .keyboardShortcut("g", modifiers: [.command, .shift])
        .disabled(findActions == nil)
    }
}
#endif

// MARK: - iOS Template Picker for DocumentGroupLaunchScene

#if os(iOS)
/// Combined template picker and blank document sheet for new manuscript
struct LaunchNewDocumentView: View {
    @Binding var continuation: CheckedContinuation<ManuscriptDocument?, any Error>?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Blank option - styled like a template card
                    Button {
                        let document = ManuscriptDocument()
                        continuation?.resume(returning: document)
                        continuation = nil
                        dismiss()
                    } label: {
                        LaunchBlankCard()
                    }
                    .buttonStyle(.plain)

                    // Template options - reuse LaunchTemplateCard
                    ForEach(BookTemplate.templates) { template in
                        Button {
                            let document = ManuscriptDocument.fromTemplate(template)
                            continuation?.resume(returning: document)
                            continuation = nil
                            dismiss()
                        } label: {
                            LaunchTemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("New Manuscript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        continuation?.resume(returning: nil)
                        continuation = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Scrivener import view for the document launch scene
struct LaunchScrivenerImportView: View {
    @Binding var continuation: CheckedContinuation<ManuscriptDocument?, any Error>?
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingFilePicker = false
    @State private var selectedURL: URL?
    @State private var isImporting = false
    @State private var importError: Error?
    @State private var validationResult: ScrivenerValidationResult?
    @State private var importProgress: Double = 0
    @State private var statusMessage = ""

    // Import options
    @State private var importResearch = true
    @State private var importTrash = false
    @State private var importSnapshots = true

    var body: some View {
        NavigationStack {
            Group {
                if isImporting {
                    importingView
                } else if let error = importError {
                    errorView(error)
                } else if let validation = validationResult, selectedURL != nil {
                    validationView(validation)
                } else {
                    selectFileView
                }
            }
            .navigationTitle("Import Scrivener")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        continuation?.resume(returning: nil)
                        continuation = nil
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.folder, .package],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    private var selectFileView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.badge.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Import Scrivener Project")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Select a .scriv project to import. Your original Scrivener project will not be modified.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                isShowingFilePicker = true
            } label: {
                Label("Select Scrivener Project", systemImage: "folder")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
            Spacer()
        }
        .padding()
    }

    private func validationView(_ result: ScrivenerValidationResult) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Project info
                VStack(spacing: 8) {
                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(result.isValid ? .green : .red)

                    Text(result.projectTitle)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(result.itemCount) items • Scrivener \(result.version == .v3 ? "3" : "2") format")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Warnings
                if !result.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Warnings", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                            .foregroundColor(.orange)

                        ForEach(result.warnings, id: \.self) { warning in
                            HStack(alignment: .top) {
                                Text("•")
                                Text(warning)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Import options
                if result.isValid {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Import Options")
                            .font(.headline)

                        Toggle("Import Research folder", isOn: $importResearch)
                        Toggle("Import Trash folder", isOn: $importTrash)
                        Toggle("Import Snapshots", isOn: $importSnapshots)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }

                // Action buttons
                HStack {
                    Button("Select Different File") {
                        selectedURL = nil
                        validationResult = nil
                        isShowingFilePicker = true
                    }

                    Spacer()

                    if result.isValid {
                        Button {
                            startImport()
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
    }

    private var importingView: some View {
        VStack(spacing: 20) {
            Spacer()

            ProgressView(value: importProgress, total: 1.0)
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            Text("Importing Project...")
                .font(.headline)

            Text(statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("\(Int(importProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Import Failed")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                importError = nil
                selectedURL = nil
                validationResult = nil
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Check if it's a .scriv bundle
            if url.pathExtension.lowercased() == "scriv" {
                selectedURL = url
                validateProject(at: url)
            } else if url.pathExtension.lowercased() == "scrivx" {
                // User selected the .scrivx file inside - use the parent directory
                let scrivURL = url.deletingLastPathComponent()
                selectedURL = scrivURL
                validateProject(at: scrivURL)
            } else {
                importError = NSError(
                    domain: "ScrivenerImport",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Please select a Scrivener project (.scriv folder)"]
                )
            }

        case .failure(let error):
            importError = error
        }
    }

    private func validateProject(at url: URL) {
        // Start security-scoped access
        let didStartAccessing = url.startAccessingSecurityScopedResource()

        Task {
            let importer = ScrivenerImporter()
            let result = importer.validateProject(at: url)

            await MainActor.run {
                validationResult = result

                if didStartAccessing {
                    // Keep access for import, will release after
                }
            }
        }
    }

    private func startImport() {
        guard let url = selectedURL else { return }

        isImporting = true
        importProgress = 0

        // Start security-scoped access
        let didStartAccessing = url.startAccessingSecurityScopedResource()

        Task {
            let importer = ScrivenerImporter()
            let options = ScrivenerImportOptions(
                importSnapshots: importSnapshots,
                importTrash: importTrash,
                importResearch: importResearch
            )

            do {
                let result = try await importer.importProject(
                    from: url,
                    options: options
                ) { progress, status in
                    Task { @MainActor in
                        self.importProgress = progress
                        self.statusMessage = status
                    }
                }

                await MainActor.run {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }

                    // Return the imported document
                    continuation?.resume(returning: result.document)
                    continuation = nil
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }

                    isImporting = false
                    importError = error
                }
            }
        }
    }
}

/// Card view for blank manuscript option in the launch picker
struct LaunchBlankCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "doc.text")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Blank Manuscript")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Start with an empty project")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [.gray.opacity(0.7), .gray.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .contentShape(Rectangle())
    }
}

/// Card view for templates in the launch picker
struct LaunchTemplateCard: View {
    let template: BookTemplate

    private var symbol: String {
        switch template.name {
        case "Hero's Journey":
            return "figure.walk.motion"
        case "Romance Outline":
            return "heart.fill"
        case "Save the Cat":
            return "cat.fill"
        default:
            return "doc.badge.plus"
        }
    }

    private var gradient: LinearGradient {
        switch template.name {
        case "Hero's Journey":
            return LinearGradient(
                colors: [.brown.opacity(0.8), Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Romance Outline":
            return LinearGradient(
                colors: [.pink.opacity(0.8), .red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Save the Cat":
            return LinearGradient(
                colors: [.orange.opacity(0.8), .yellow.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(template.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(gradient)
        )
        .contentShape(Rectangle())
    }
}
#endif

// MARK: - macOS Welcome Window

#if os(macOS)
/// Wrapper view for WelcomeView that provides access to openDocument environment action
struct WelcomeWindowContent: View {
    @ObservedObject var recentDocumentsManager: RecentDocumentsManager
    @ObservedObject var notificationManager: NotificationManager

    @Environment(\.openDocument) private var openDocument

    var body: some View {
        WelcomeView(
            onOpenDocument: { url in
                openDocumentAtURL(url)
            },
            onCreateNewDocument: {
                NSApp.sendAction(#selector(NSDocumentController.newDocument(_:)), to: nil, from: nil)
            },
            onImportDocument: { importedDocument in
                saveAndOpenImportedDocument(importedDocument)
            }
        )
        .environmentObject(recentDocumentsManager)
        .environmentObject(notificationManager)
    }

    private func openDocumentAtURL(_ url: URL) {
        // Start security-scoped access
        let didStartAccessing = url.startAccessingSecurityScopedResource()

        Task {
            do {
                try await openDocument(at: url)
            } catch {
                print("Error opening document: \(error.localizedDescription)")
            }

            // Stop accessing after a delay to ensure document is loaded
            if didStartAccessing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }

    /// Save an imported document and prompt user to choose save location
    private func saveAndOpenImportedDocument(_ document: ManuscriptDocument) {
        do {
            // Create the package using the document's createPackageFileWrapper method
            let fileWrapper = try document.createPackageFileWrapper()

            // Create a save panel to let user choose where to save
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.manuscriptDocument]
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            savePanel.title = "Save Imported Project"
            savePanel.message = "Choose where to save your imported Scrivener project"
            savePanel.nameFieldStringValue = document.title.isEmpty ? "Imported Project.manuscript" : "\(document.title).manuscript"

            savePanel.begin { response in
                guard response == .OK, let url = savePanel.url else {
                    print("User cancelled save")
                    return
                }

                do {
                    // Write the file wrapper to the chosen location
                    try fileWrapper.write(
                        to: url,
                        options: [.atomic],
                        originalContentsURL: nil
                    )

                    // Open the document using SwiftUI's openDocument environment action
                    // This properly handles the UTType through DocumentGroup
                    Task {
                        do {
                            try await openDocument(at: url)
                        } catch {
                            print("Error opening imported document: \(error.localizedDescription)")
                        }
                    }
                } catch {
                    print("Error saving imported document: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error creating file wrapper for imported document: \(error.localizedDescription)")
        }
    }
}
#endif

@main
struct ManuscriptApp: App {
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var recentDocumentsManager = RecentDocumentsManager()
    @State private var isShowingWelcomeScreen = true
    @State private var documentURL: URL?

    // iOS 18 DocumentGroupLaunchScene state
    #if os(iOS)
    @State private var newDocContinuation: CheckedContinuation<ManuscriptDocument?, any Error>?
    @State private var isNewDocPresented = false
    @State private var importContinuation: CheckedContinuation<ManuscriptDocument?, any Error>?
    @State private var isScrivenerImportPresented = false
    #endif

    init() {
        // Debug: Print iCloud status on launch
        printICloudDebugInfo()
    }

    private func printICloudDebugInfo() {
        print("=== iCloud Debug Info ===")
        #if os(iOS)
        print("Platform: iOS")
        #else
        print("Platform: macOS")
        #endif
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

        // Check default container (nil) - should be generic iCloud Drive
        if let defaultURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            print("✅ iCloud container accessible at:")
            print("   \(defaultURL.path)")

            let documentsURL = defaultURL.appendingPathComponent("Documents")
            if FileManager.default.fileExists(atPath: documentsURL.path) {
                if let files = try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
                    print("   Found \(files.count) file(s) in Documents/:")
                    for file in files.prefix(10) {
                        print("   - \(file.lastPathComponent)")
                    }
                }
            }
        } else {
            print("❌ Cannot access iCloud container")
        }
        print("========================\n")
    }

    var body: some Scene {
        #if os(macOS)
        // Welcome window (macOS only)
        WindowGroup("Welcome to Manuscript", id: "welcome") {
            WelcomeWindowContent(
                recentDocumentsManager: recentDocumentsManager,
                notificationManager: notificationManager
            )
            .containerBackground(.ultraThinMaterial, for: .window)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        }
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
        .windowResizability(.contentSize)
        .defaultSize(width: 720, height: 460)
        #endif

        // Document-based app structure
        DocumentGroup(newDocument: ManuscriptDocument()) { file in
            ManuscriptProjectView(document: file.$document, fileURL: file.fileURL)
                .environmentObject(notificationManager)
                .environmentObject(recentDocumentsManager)
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 600)
                #endif
                .onAppear {
                    // Add to recent documents when opened
                    if let url = file.fileURL {
                        recentDocumentsManager.addDocument(url: url, title: file.document.title.isEmpty ? "Untitled" : file.document.title)
                    }
                }
        }
        #if os(macOS)
        .defaultWindowPlacement { content, context in
            // Use NSScreen.main to get the display with keyboard focus (where user is working)
            if let mainScreen = NSScreen.main {
                let visibleFrame = mainScreen.visibleFrame
                return WindowPlacement(
                    CGPoint(x: visibleFrame.origin.x, y: visibleFrame.origin.y),
                    size: CGSize(width: visibleFrame.width, height: visibleFrame.height)
                )
            }
            // Fallback to context's default display
            let displayBounds = context.defaultDisplay.visibleRect
            return WindowPlacement(size: CGSize(width: displayBounds.width, height: displayBounds.height))
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Show Welcome Screen") {
                    isShowingWelcomeScreen = true
                    NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
                    NSApp.windows.first(where: { $0.title == "Welcome to Manuscript" })?.makeKeyAndOrderFront(nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            // Find menu commands
            CommandGroup(after: .textEditing) {
                FindMenuCommands()
            }
        }
        #endif

        // iOS 18+ Document Launch Scene
        #if os(iOS)
        DocumentGroupLaunchScene("") {
            NewDocumentButton("New Manuscript", for: ManuscriptDocument.self) {
                try await withCheckedThrowingContinuation { continuation in
                    self.newDocContinuation = continuation
                    self.isNewDocPresented = true
                }
            }
            .sheet(isPresented: $isNewDocPresented) {
                LaunchNewDocumentView(continuation: $newDocContinuation)
            }

            NewDocumentButton("Import Scrivener", for: ManuscriptDocument.self) {
                try await withCheckedThrowingContinuation { continuation in
                    self.importContinuation = continuation
                    self.isScrivenerImportPresented = true
                }
            }
            .sheet(isPresented: $isScrivenerImportPresented) {
                LaunchScrivenerImportView(continuation: $importContinuation)
            }
        } background: {
            // Warm paper-like gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.94, blue: 0.90),  // Warm cream
                    Color(red: 0.92, green: 0.88, blue: 0.82),  // Light tan
                    Color(red: 0.85, green: 0.80, blue: 0.72)   // Deeper tan
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        } overlayAccessoryView: { geometry in
            // Custom smaller title - at top of white card, above buttons
            Text("Manuscript")
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.15))
                .position(
                    x: geometry.titleViewFrame.midX,
                    y: geometry.titleViewFrame.minY + 10
                )

        }
        #endif

        #if os(macOS)
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(notificationManager)
        }
        #endif
    }

}
