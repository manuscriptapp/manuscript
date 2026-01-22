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
                outline: docTemplate.outline,
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

// MARK: - iOS Template Picker for DocumentGroupLaunchScene

#if os(iOS)
/// Template picker sheet for the document launch scene
struct LaunchTemplatePickerView: View {
    @Binding var continuation: CheckedContinuation<ManuscriptDocument?, any Error>?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
            .navigationTitle("Choose a Template")
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

/// Card view for templates in the launch picker
struct LaunchTemplateCard: View {
    let template: BookTemplate

    private var symbol: String {
        switch template.name {
        case "Hero's Journey":
            return "figure.walk.motion"
        case "Romance Outline":
            return "heart.fill"
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
    @State private var templateContinuation: CheckedContinuation<ManuscriptDocument?, any Error>?
    @State private var isTemplatePickerPresented = false
    @State private var isSettingsPresented = false
    @State private var isHowItWorksPresented = false
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
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
        #endif

        // Document-based app structure
        DocumentGroup(newDocument: ManuscriptDocument()) { file in
            ManuscriptProjectView(document: file.$document)
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
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Show Welcome Screen") {
                    isShowingWelcomeScreen = true
                    NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
                    NSApp.windows.first(where: { $0.title == "Welcome to Manuscript" })?.makeKeyAndOrderFront(nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
        #endif

        // iOS 18+ Document Launch Scene
        #if os(iOS)
        DocumentGroupLaunchScene("") {
            NewDocumentButton("New Manuscript")

            NewDocumentButton("Choose Template", for: ManuscriptDocument.self) {
                try await withCheckedThrowingContinuation { continuation in
                    self.templateContinuation = continuation
                    self.isTemplatePickerPresented = true
                }
            }
            .sheet(isPresented: $isTemplatePickerPresented) {
                LaunchTemplatePickerView(continuation: $templateContinuation)
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

            // Bottom buttons row - Settings and How It Works
            HStack(spacing: 24) {
                Button {
                    isSettingsPresented = true
                } label: {
                    Label("Settings", systemImage: "gear")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.45, green: 0.35, blue: 0.25))
                }

                Button {
                    isHowItWorksPresented = true
                } label: {
                    Label("How It Works", systemImage: "questionmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.45, green: 0.35, blue: 0.25))
                }
            }
            .position(
                x: geometry.titleViewFrame.midX,
                y: geometry.titleViewFrame.maxY + 100
            )
        }
        .sheet(isPresented: $isSettingsPresented) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isSettingsPresented = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $isHowItWorksPresented) {
            NavigationStack {
                HowItWorksView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isHowItWorksPresented = false
                            }
                        }
                    }
            }
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
