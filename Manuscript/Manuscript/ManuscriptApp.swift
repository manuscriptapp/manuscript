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

/// Menu commands for Composition Mode
struct CompositionModeMenuCommands: View {
    @FocusedValue(\.compositionModeBinding) var compositionModeBinding

    var body: some View {
        Button("Enter Composition Mode") {
            withAnimation(.spring(duration: 0.4)) {
                compositionModeBinding?.wrappedValue = true
            }
        }
        .keyboardShortcut(.return, modifiers: [.command, .shift])
        .disabled(compositionModeBinding == nil)
    }
}

/// Menu commands for Export functionality in the File menu
struct ExportMenuCommands: View {
    @FocusedValue(\.exportSheetBinding) var exportSheetBinding

    var body: some View {
        Button("Export…") {
            exportSheetBinding?.wrappedValue = true
        }
        .keyboardShortcut("e", modifiers: [.command, .shift])
        .disabled(exportSheetBinding == nil)
    }
}

/// Menu commands for Print functionality in the File menu
struct PrintMenuCommands: View {
    @FocusedValue(\.printSheetBinding) var printSheetBinding

    var body: some View {
        Button("Print…") {
            printSheetBinding?.wrappedValue = true
        }
        .keyboardShortcut("p", modifiers: .command)
        .disabled(printSheetBinding == nil)
    }
}

/// Menu commands for Formatting Toolbar toggle in View menu
struct FormattingToolbarMenuCommands: View {
    @AppStorage("showFormattingToolbar") private var showFormattingToolbar: Bool = true

    var body: some View {
        Toggle("Show Formatting Toolbar", isOn: $showFormattingToolbar)
            .keyboardShortcut("t", modifiers: [.command, .option])
    }
}
#endif

// MARK: - iOS Launch Scene Components

#if os(iOS)
/// Adaptive background for the document launch scene
struct LaunchSceneBackground: View {
    @Environment(\.appTheme) private var appTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    appTheme.backgroundColor,
                    appTheme.groupedBackgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

/// Adaptive title for the document launch scene with animated gradient
struct LaunchSceneTitle: View {
    @Environment(\.colorScheme) private var colorScheme
    private let startDate = Date()

    // Gradient colors - earthy editorial tones: browns, grays, dark greens
    private var gradientColor1: Color {
        colorScheme == .dark
            ? Color(red: 0.75, green: 0.65, blue: 0.55)  // warm brown
            : Color(red: 0.45, green: 0.35, blue: 0.25)   // rich brown
    }

    private var gradientColor2: Color {
        colorScheme == .dark
            ? Color(red: 0.6, green: 0.6, blue: 0.58)    // warm gray
            : Color(red: 0.4, green: 0.4, blue: 0.38)     // slate gray
    }

    private var gradientColor3: Color {
        colorScheme == .dark
            ? Color(red: 0.45, green: 0.55, blue: 0.45)  // forest green
            : Color(red: 0.2, green: 0.35, blue: 0.25)    // dark green
    }

    private var secondaryColor: Color {
        colorScheme == .dark ? .white.opacity(0.45) : Color(white: 0.45)
    }

    var body: some View {
        VStack(spacing: 10) {
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                let time = Float(timeline.date.timeIntervalSince(startDate))

                Text("manuscript")
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .colorEffect(
                        ShaderLibrary.gradientShift(
                            .float(time),
                            .color(gradientColor1),
                            .color(gradientColor2),
                            .color(gradientColor3)
                        )
                    )
            }

            Text("for writers, by writers")
                .font(.system(size: 13, weight: .regular, design: .default))
                .tracking(0.5)
                .foregroundStyle(secondaryColor)
        }
    }
}

// MARK: - iOS Template Picker for DocumentGroupLaunchScene
/// Combined template picker and blank document sheet for new manuscript
struct LaunchNewDocumentView: View {
    @Binding var continuation: CheckedContinuation<ManuscriptDocument?, any Error>?
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Title")
                            .font(.headline)

                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)

                        if trimmedTitle.isEmpty {
                            Text("Title is required to create a new manuscript.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.bottom, 4)

                    // Blank option - styled like a template card
                    Button {
                        print("📝 [LaunchNewDocumentView] Creating blank document")
                        var document = ManuscriptDocument()
                        document.title = trimmedTitle
                        print("   - Document created with title: '\(document.title)'")
                        print("   - Continuation available: \(continuation != nil)")
                        continuation?.resume(returning: document)
                        continuation = nil
                        dismiss()
                    } label: {
                        LaunchBlankCard()
                    }
                    .disabled(trimmedTitle.isEmpty)
                    .buttonStyle(.plain)

                    // Template options - reuse LaunchTemplateCard
                    ForEach(BookTemplate.templates) { template in
                        Button {
                            print("📝 [LaunchNewDocumentView] Creating document from template: \(template.name)")
                            let document = ManuscriptDocument.fromTemplate(template, title: trimmedTitle)
                            print("   - Document created with title: '\(document.title)'")
                            print("   - Continuation available: \(continuation != nil)")
                            continuation?.resume(returning: document)
                            continuation = nil
                            dismiss()
                        } label: {
                            LaunchTemplateCard(template: template)
                        }
                        .disabled(trimmedTitle.isEmpty)
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
                        print("📝 [LaunchNewDocumentView] User cancelled")
                        print("   - Continuation available: \(continuation != nil)")
                        continuation?.resume(returning: nil)
                        continuation = nil
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            print("📝 [LaunchNewDocumentView] Sheet appeared")
            print("   - Continuation available: \(continuation != nil)")
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
            .navigationTitle("Import Scrivener Project")
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
            .manuscriptPrimaryButton()

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
                        .manuscriptPrimaryButton()
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
            .manuscriptPrimaryButton()

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
    @StateObject private var backupManager = BackupManager()
    @State private var themeManager = ThemeManager()
    @State private var isShowingWelcomeScreen = true
    @State private var documentURL: URL?
    #if os(iOS)
    @State private var renameAttempts: [URL: Int] = [:]
    #endif

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
        print("Platform: iOS Simulator/Device")
        #else
        print("Platform: macOS")
        #endif
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

        // Check iCloud account status
        let fileManager = FileManager.default
        print("ubiquityIdentityToken: \(fileManager.ubiquityIdentityToken != nil ? "present" : "nil (not logged in or iCloud disabled)")")

        // Check default container (nil) - should be generic iCloud Drive
        if let defaultURL = fileManager.url(forUbiquityContainerIdentifier: nil) {
            print("✅ iCloud container accessible at:")
            print("   \(defaultURL.path)")

            let documentsURL = defaultURL.appendingPathComponent("Documents")
            print("   Documents path: \(documentsURL.path)")
            print("   Documents exists: \(fileManager.fileExists(atPath: documentsURL.path))")

            if fileManager.fileExists(atPath: documentsURL.path) {
                do {
                    let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.isDirectoryKey, .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
                    print("   Found \(files.count) file(s) in Documents/:")
                    for file in files.prefix(10) {
                        let resourceValues = try? file.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
                        let downloadStatus = resourceValues?.ubiquitousItemDownloadingStatus?.rawValue ?? "unknown"
                        print("   - \(file.lastPathComponent) (iCloud status: \(downloadStatus))")
                    }
                } catch {
                    print("   ❌ Error reading Documents: \(error.localizedDescription)")
                }
            }
        } else {
            print("❌ Cannot access iCloud container (url(forUbiquityContainerIdentifier:) returned nil)")
            print("   This usually means:")
            print("   - iCloud is not enabled for this app")
            print("   - User is not signed into iCloud")
            print("   - Running on Simulator without iCloud configured")
        }

        // Check local documents directory as fallback
        let localDocs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        print("Local Documents: \(localDocs?.path ?? "nil")")
        if let localDocs = localDocs {
            do {
                let localFiles = try fileManager.contentsOfDirectory(at: localDocs, includingPropertiesForKeys: nil)
                print("   Found \(localFiles.count) local file(s)")
            } catch {
                print("   ❌ Error reading local docs: \(error.localizedDescription)")
            }
        }

        print("========================\n")
    }

    var body: some Scene {
        #if os(macOS)
        // Welcome window (macOS only)
        WindowGroup("Welcome to Manuscript", id: "welcome") {
            AppThemeContainer(theme: themeManager.selectedTheme) {
                WelcomeWindowContent(
                    recentDocumentsManager: recentDocumentsManager,
                    notificationManager: notificationManager
                )
                .frame(width: 850, height: 500)
                .containerBackground(.ultraThinMaterial, for: .window)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            }
            .environment(themeManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
        .windowResizability(.contentSize)
        #endif

        // Document-based app structure
        DocumentGroup(newDocument: ManuscriptDocument()) { file in
            AppThemeContainer(theme: themeManager.selectedTheme) {
                ManuscriptProjectView(document: file.$document, fileURL: file.fileURL)
                    .environmentObject(notificationManager)
                    .environmentObject(recentDocumentsManager)
                    .environment(themeManager)
                    .withErrorAlert()
                    #if os(macOS)
                    .frame(minWidth: 900, minHeight: 600)
                    #endif
                    .onAppear {
                        print("📂 [DocumentGroup] Document opened")
                        print("   - fileURL: \(file.fileURL?.path ?? "nil (new document)")")
                        print("   - title: \(file.document.title.isEmpty ? "(empty)" : file.document.title)")
                        print("   - rootFolder documents: \(file.document.rootFolder.documents.count)")
                        print("   - characters: \(file.document.characters.count)")
                        print("   - locations: \(file.document.locations.count)")

                        #if os(iOS)
                        handleDocumentOpen(
                            fileURL: file.fileURL,
                            title: file.document.title
                        )
                        #else
                        if let url = file.fileURL {
                            recentDocumentsManager.addDocument(url: url, title: file.document.title.isEmpty ? "Untitled" : file.document.title)
                        }
                        #endif
                    }
                    #if os(iOS)
                    .onChange(of: file.fileURL) { _, newURL in
                        guard let newURL else { return }
                        handleDocumentOpen(
                            fileURL: newURL,
                            title: file.document.title
                        )
                    }
                    .onChange(of: file.document.title) { _, newTitle in
                        handleDocumentOpen(
                            fileURL: file.fileURL,
                            title: newTitle
                        )
                    }
                    #endif
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

            // View menu commands - Composition Mode, Formatting Toolbar
            CommandGroup(after: .toolbar) {
                CompositionModeMenuCommands()
                Divider()
                FormattingToolbarMenuCommands()
            }

            // File menu commands - Export and Print
            CommandGroup(after: .importExport) {
                ExportMenuCommands()
                PrintMenuCommands()
            }
        }
        #endif

        // iOS 18+ Document Launch Scene
        #if os(iOS)
        DocumentGroupLaunchScene("") {
            NewDocumentButton("New Manuscript", for: ManuscriptDocument.self) {
                print("🆕 [DocumentGroupLaunchScene] 'New Manuscript' button tapped")
                do {
                    let result = try await withCheckedThrowingContinuation { continuation in
                        print("   - Setting up continuation for new document")
                        self.newDocContinuation = continuation
                        self.isNewDocPresented = true
                    }
                    print("   - Continuation resolved with document: \(result?.title ?? "nil")")
                    return result
                } catch {
                    print("❌ [DocumentGroupLaunchScene] Error creating new document: \(error)")
                    throw error
                }
            }
            .sheet(isPresented: $isNewDocPresented) {
                LaunchNewDocumentView(continuation: $newDocContinuation)
            }

            NewDocumentButton("Import Scrivener Project", for: ManuscriptDocument.self) {
                print("📥 [DocumentGroupLaunchScene] 'Import Scrivener Project' button tapped")
                do {
                    let result = try await withCheckedThrowingContinuation { continuation in
                        print("   - Setting up continuation for Scrivener import")
                        self.importContinuation = continuation
                        self.isScrivenerImportPresented = true
                    }
                    print("   - Import continuation resolved with document: \(result?.title ?? "nil")")
                    return result
                } catch {
                    print("❌ [DocumentGroupLaunchScene] Error importing Scrivener project: \(error)")
                    throw error
                }
            }
            .sheet(isPresented: $isScrivenerImportPresented) {
                LaunchScrivenerImportView(continuation: $importContinuation)
            }
        } background: {
            LaunchSceneBackground()
                .applyAppTheme(themeManager.selectedTheme)
                .onAppear {
                    print("📱 [DocumentGroupLaunchScene] Launch scene background appeared")
                }
        } overlayAccessoryView: { geometry in
            // Title with extra margin above buttons
            LaunchSceneTitle()
                .position(
                    x: geometry.titleViewFrame.midX,
                    y: geometry.titleViewFrame.minY - 8
                )
        }
        #endif

        #if os(macOS)
        // Settings window
        Settings {
            AppThemeContainer(theme: themeManager.selectedTheme) {
                SettingsView()
                    .environmentObject(backupManager)
                    .environmentObject(notificationManager)
                    .environment(themeManager)
            }
        }
        #endif
    }

    #if os(iOS)
    private func handleDocumentOpen(fileURL: URL?, title: String) {
        guard let fileURL else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentName = fileURL.deletingPathExtension().lastPathComponent
        let shouldRename = !trimmedTitle.isEmpty && currentName.hasPrefix("Untitled")

        if shouldRename {
            scheduleRename(fileURL: fileURL, title: trimmedTitle)
        } else {
            recentDocumentsManager.addDocument(url: fileURL, title: title.isEmpty ? "Untitled" : title)
        }
    }

    private func scheduleRename(fileURL: URL, title: String) {
        let attempts = renameAttempts[fileURL, default: 0]
        let maxAttempts = 3
        if attempts >= maxAttempts {
            renameAttempts[fileURL] = nil
            recentDocumentsManager.addDocument(url: fileURL, title: title.isEmpty ? "Untitled" : title)
            return
        }

        renameAttempts[fileURL] = attempts + 1
        let delay: TimeInterval
        switch attempts {
        case 0: delay = 0.0
        case 1: delay = 0.3
        default: delay = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let titleForRename = title
            DispatchQueue.global(qos: .utility).async {
                let renamedURL = renameDocumentIfNeeded(fileURL: fileURL, title: titleForRename)
                DispatchQueue.main.async {
                    if let renamedURL {
                        self.renameAttempts[fileURL] = nil
                        self.recentDocumentsManager.addDocument(
                            url: renamedURL,
                            title: titleForRename.isEmpty ? "Untitled" : titleForRename
                        )
                    } else {
                        self.scheduleRename(fileURL: fileURL, title: titleForRename)
                    }
                }
            }
        }
    }

    private func renameDocumentIfNeeded(fileURL: URL, title: String) -> URL? {
        print("🔎 [DocumentGroup] Rename check for: \(fileURL.lastPathComponent) (title: '\(title)')")

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            print("⚠️ [DocumentGroup] Rename skipped: empty title")
            return nil
        }

        let currentName = fileURL.deletingPathExtension().lastPathComponent
        guard currentName.hasPrefix("Untitled") else {
            print("ℹ️ [DocumentGroup] Rename skipped: already named '\(currentName)'")
            return nil
        }

        let sanitizedTitle = sanitizedFilename(from: trimmedTitle)
        guard !sanitizedTitle.isEmpty else {
            print("⚠️ [DocumentGroup] Rename skipped: sanitized title empty")
            return nil
        }

        let directory = fileURL.deletingLastPathComponent()
        let fileExtension = fileURL.pathExtension.isEmpty ? "manuscript" : fileURL.pathExtension
        let targetURL = uniqueFileURL(
            baseName: sanitizedTitle,
            directory: directory,
            fileExtension: fileExtension,
            excluding: fileURL
        )

        guard targetURL != fileURL else {
            print("ℹ️ [DocumentGroup] Rename skipped: target equals current URL")
            return nil
        }

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: fileURL.path) {
            if fileManager.fileExists(atPath: targetURL.path) {
                return targetURL
            }
            print("⚠️ [DocumentGroup] Rename skipped: source file missing")
            return nil
        }

        var coordinatorError: NSError?
        var finalURL: URL? = fileURL
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(writingItemAt: fileURL, options: .forMoving, error: &coordinatorError) { coordinatedURL in
            do {
                try fileManager.moveItem(at: coordinatedURL, to: targetURL)
                print("✅ [DocumentGroup] Renamed document to: \(targetURL.lastPathComponent)")
                finalURL = targetURL
            } catch {
                print("❌ [DocumentGroup] Failed to rename document: \(error.localizedDescription)")
                finalURL = nil
            }
        }
        if let coordinatorError {
            print("❌ [DocumentGroup] File coordination error: \(coordinatorError.localizedDescription)")
        }
        return finalURL == fileURL ? nil : finalURL
    }

    private func sanitizedFilename(from title: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = title
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
        let collapsed = cleaned
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return collapsed
    }

    private func uniqueFileURL(
        baseName: String,
        directory: URL,
        fileExtension: String,
        excluding originalURL: URL
    ) -> URL {
        var candidate = directory
            .appendingPathComponent(baseName)
            .appendingPathExtension(fileExtension)
        if candidate == originalURL {
            return candidate
        }

        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let numberedName = "\(baseName) \(counter)"
            candidate = directory
                .appendingPathComponent(numberedName)
                .appendingPathExtension(fileExtension)
            counter += 1
        }
        return candidate
    }
    #endif

}
