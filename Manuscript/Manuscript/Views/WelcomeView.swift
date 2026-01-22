import SwiftUI
import UniformTypeIdentifiers
import Foundation
#if os(macOS)
import AppKit
#endif

struct WelcomeView: View {
    @EnvironmentObject private var recentDocumentsManager: RecentDocumentsManager
    @State private var isShowingNewProjectSheet = false
    @State private var isShowingFileImporter = false
    @State private var isShowingScrivenerImporter = false
    @State private var selectedTemplate: BookTemplate?
    @State private var isShowingTemplateDetail = false

    var onOpenDocument: (URL) -> Void
    var onCreateNewDocument: () -> Void
    var onImportDocument: ((ManuscriptDocument) -> Void)?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome to Manuscript")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Your writing companion")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Recent documents
                    if !recentDocumentsManager.recentDocuments.isEmpty {
                        recentDocumentsSection
                    }
                    
                    // Templates
                    templatesSection
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewDocument()
                    } label: {
                        Label("New Document", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingNewProjectSheet) {
                NewBookSheet { document in
                    // Create a new document and open it
                    #if os(macOS)
                    // On macOS, the document is already saved by the NewBookSheet
                    onCreateNewDocument()
                    #else
                    // On iOS, we need to save the document
                    saveDocument(document)
                    #endif
                }
            }
            .sheet(isPresented: $isShowingTemplateDetail) {
                if let template = selectedTemplate {
                    TemplateDetailSheet(template: template) {
                        // Create a new document with the template
                        onCreateNewDocument()
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.manuscriptDocument],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        openExistingDocument(at: url)
                    }
                case .failure(let error):
                    print("Error importing file: \(error.localizedDescription)")
                }
            }
            .sheet(isPresented: $isShowingScrivenerImporter) {
                ScrivenerImportView { importedDocument in
                    onImportDocument?(importedDocument)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var quickActionsSection: some View {
        #if os(macOS)
        HStack(spacing: 16) {
            quickActionButton(
                title: "New Project",
                systemImage: "doc.badge.plus",
                action: { createNewDocument() }
            )

            quickActionButton(
                title: "Open Project",
                systemImage: "folder",
                action: { openProjectWithPanel() }
            )

            quickActionButton(
                title: "Import Scrivener",
                systemImage: "square.and.arrow.down",
                action: { isShowingScrivenerImporter = true }
            )
        }
        .padding(.bottom, 8)
        #else
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.headline)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

            LazyVGrid(columns: columns, spacing: 12) {
                quickActionButton(
                    title: "New Project",
                    systemImage: "doc.badge.plus",
                    action: { createNewDocument() }
                )

                quickActionButton(
                    title: "Open Project",
                    systemImage: "folder",
                    action: { isShowingFileImporter = true }
                )

                quickActionButton(
                    title: "Import Scrivener",
                    systemImage: "square.and.arrow.down",
                    action: { isShowingScrivenerImporter = true }
                )
            }
        }
        .padding(.bottom, 8)
        #endif
    }
    
    private var recentDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Projects")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button("Clear All") {
                    recentDocumentsManager.clearRecentDocuments()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            #if os(macOS)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentDocumentsManager.recentDocuments) { document in
                        RecentDocumentCard(document: document) {
                            openRecentDocument(document)
                        }
                        .frame(width: 180)
                        .contextMenu {
                            Button(action: {
                                recentDocumentsManager.removeDocument(at: document.url)
                            }) {
                                Label("Remove from Recent", systemImage: "trash")
                            }

                            Button(action: {
                                NSWorkspace.shared.selectFile(document.url.path, inFileViewerRootedAtPath: document.url.deletingLastPathComponent().path)
                            }) {
                                Label("Show in Finder", systemImage: "folder")
                            }
                        }
                    }
                }
            }
            #else
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(recentDocumentsManager.recentDocuments) { document in
                    RecentDocumentCard(document: document) {
                        openRecentDocument(document)
                    }
                    .contextMenu {
                        Button(action: {
                            recentDocumentsManager.removeDocument(at: document.url)
                        }) {
                            Label("Remove from Recent", systemImage: "trash")
                        }
                    }
                }
            }
            #endif
        }
        .padding(.bottom, 8)
    }
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Templates")
                .font(.title3)
                .bold()
            
            #if os(macOS)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    BlankTemplateCard {
                        selectedTemplate = nil
                        isShowingTemplateDetail = true
                    }
                    .frame(width: 140)
                    
                    ForEach(BookTemplate.templates, id: \.id) { template in
                        TemplateCardView(template: template)
                            .frame(width: 140)
                            .onTapGesture {
                                selectedTemplate = template
                                isShowingTemplateDetail = true
                            }
                    }
                }
                .padding(.bottom)
            }
            #else
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
            
            LazyVGrid(columns: columns, spacing: 12) {
                BlankTemplateCard {
                    selectedTemplate = nil
                    isShowingTemplateDetail = true
                }
                
                ForEach(BookTemplate.templates, id: \.id) { template in
                    TemplateCardView(template: template)
                        .onTapGesture {
                            selectedTemplate = template
                            isShowingTemplateDetail = true
                        }
                }
            }
            #endif
        }
    }
    
    // MARK: - Helper Views
    
    private func quickActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods

    private func createNewDocument() {
        // Use the callback - on macOS it uses NSDocumentController,
        // on iOS this triggers the DocumentGroup to create a new document
        onCreateNewDocument()
    }

    private func openExistingDocument(at url: URL) {
        // Use the callback - on macOS this goes through WelcomeWindowContent
        // which has access to the openDocument environment action
        onOpenDocument(url)
    }

    #if os(macOS)
    /// Opens an NSOpenPanel configured for .manuscript package documents
    private func openProjectWithPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.treatsFilePackagesAsDirectories = false  // Treat .manuscript packages as single selectable items
        panel.allowedContentTypes = [.folder, .package, .item]  // Allow folders and packages
        panel.message = "Select a Manuscript project (.manuscript)"
        panel.prompt = "Open"

        if panel.runModal() == .OK, let url = panel.url {
            // Verify it's a .manuscript package
            if url.pathExtension.lowercased() == "manuscript" {
                openExistingDocument(at: url)
            }
        }
    }
    #endif

    /// Opens a recent document, resolving its security-scoped bookmark first
    private func openRecentDocument(_ document: RecentDocument) {
        #if os(macOS)
        // Try to resolve the bookmark first for security-scoped access
        if let resolvedURL = recentDocumentsManager.resolveBookmark(for: document) {
            openExistingDocument(at: resolvedURL)
        } else {
            // Fallback: try opening directly (may fail for iCloud files without bookmark)
            print("Warning: Could not resolve bookmark for \(document.title), trying direct URL")
            openExistingDocument(at: document.url)
        }
        #else
        // On iOS, just open directly - the system handles sandbox access differently
        openExistingDocument(at: document.url)
        #endif
    }

    // Helper method to save a document on iOS
    #if os(iOS)
    private func saveDocument(_ document: ManuscriptDocument) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(document)
            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            let fileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("manuscript")
            try data.write(to: fileURL)
            openExistingDocument(at: fileURL)
        } catch {
            print("Error saving document: \(error.localizedDescription)")
        }
    }
    #endif
}

struct RecentDocumentCard: View {
    let document: RecentDocument
    let action: () -> Void
    
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.7), .teal.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "doc.text.fill")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(document.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text(document.url.lastPathComponent)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                
                Text(document.lastOpenedDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct BlankTemplateCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 120)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "plus.square.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                        
                        Text("Start Fresh")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }
                
                Text("Blank Book")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WelcomeView(
        onOpenDocument: { _ in },
        onCreateNewDocument: { },
        onImportDocument: { _ in }
    )
    .environmentObject(RecentDocumentsManager())
} 
