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
                .onAppear {
                    // Add to recent documents when opened
                    if let url = file.fileURL {
                        recentDocumentsManager.addDocument(url: url, title: file.document.title.isEmpty ? "Untitled" : file.document.title)
                    }
                }
        }
        #if os(macOS)
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

        #if os(macOS)
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(notificationManager)
        }
        #endif
    }

}
