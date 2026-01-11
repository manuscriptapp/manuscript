//
//  ManuscriptApp.swift
//  Manuscript
//
//  Created by Jonas Dalesjö on 2025-02-16.
//

import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

@main
struct ManuscriptApp: App {
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var recentDocumentsManager = RecentDocumentsManager()
    @State private var isShowingWelcomeScreen = true
    @State private var documentURL: URL?

    var body: some Scene {
        #if os(macOS)
        // Welcome window (macOS only)
        WindowGroup("Welcome to Manuscript", id: "welcome") {
            WelcomeView(
                onOpenDocument: { url in
                    documentURL = url
                    isShowingWelcomeScreen = false
                    NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
                },
                onCreateNewDocument: {
                    documentURL = nil
                    isShowingWelcomeScreen = false
                    do {
                        try NSDocumentController.shared.openUntitledDocumentAndDisplay(true)
                    } catch {
                        print("Error creating new document: \(error.localizedDescription)")
                    }
                },
                onImportDocument: { importedDocument in
                    // Save the imported document and open it
                    saveAndOpenImportedDocument(importedDocument)
                    isShowingWelcomeScreen = false
                }
            )
            .environmentObject(recentDocumentsManager)
            .environmentObject(notificationManager)
            .onDisappear {
                if !isShowingWelcomeScreen {
                    NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "welcome" })?.close()
                }
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
        #endif

        // Document-based app structure
        DocumentGroup(newDocument: ManuscriptDocument()) { file in
            ManuscriptProjectView(document: file.$document)
                .environmentObject(notificationManager)
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

    #if os(macOS)
    /// Save an imported document to a temporary file and open it
    private func saveAndOpenImportedDocument(_ document: ManuscriptDocument) {
        // Create a temporary file for the imported document
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = document.title.isEmpty ? "Imported Project" : document.title
        let sanitizedFileName = fileName.replacingOccurrences(of: "/", with: "-")
        let tempURL = tempDir.appendingPathComponent("\(sanitizedFileName).manuscript")

        do {
            // Encode the document
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(document)

            // Write to temp file
            try data.write(to: tempURL)

            // Open the document
            NSDocumentController.shared.openDocument(withContentsOf: tempURL, display: true) { nsDocument, _, error in
                if let error = error {
                    print("Error opening imported document: \(error.localizedDescription)")
                } else if let nsDocument = nsDocument {
                    // Mark as unsaved so user is prompted to save to a permanent location
                    nsDocument.updateChangeCount(.changeDone)
                }
            }
        } catch {
            print("Error saving imported document: \(error.localizedDescription)")
        }
    }
    #endif
}
