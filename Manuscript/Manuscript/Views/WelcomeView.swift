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
    @State private var templateToShow: BookTemplate?
    @State private var shuffledTemplates: [BookTemplate] = BookTemplate.templates.shuffled()

    var onOpenDocument: (URL) -> Void
    var onCreateNewDocument: () -> Void
    var onImportDocument: ((ManuscriptDocument) -> Void)?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome to Manuscript")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .tracking(-0.5)

                        Text("For writers, by writers")
                            .font(.system(size: 15, weight: .regular))
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

                    // Footer
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            #if os(macOS)
            .scrollContentBackground(.hidden)
            #endif
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(macOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Spacer()
                }
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button {
                            // Placeholder
                        } label: {
                            Label("About Manuscript", systemImage: "info.circle")
                        }

                        Divider()

                        Button {
                            // Placeholder
                        } label: {
                            Label("Check for Updates", systemImage: "arrow.clockwise")
                        }

                        Button {
                            // Placeholder
                        } label: {
                            Label("Send Feedback", systemImage: "envelope")
                        }

                        Divider()

                        Button {
                            // Placeholder
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewDocument()
                    } label: {
                        Label("New Document", systemImage: "plus")
                    }
                }
            }
            #endif
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
            .sheet(item: $templateToShow) { template in
                TemplateDetailSheet(template: template) {
                    // Document is saved and opened by NewBookSheet
                    // No need to create another document here
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
        HStack(spacing: 12) {
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
                title: "Import Scrivener Project",
                systemImage: "square.and.arrow.down",
                action: { isShowingScrivenerImporter = true }
            )
        }
        .fixedSize(horizontal: false, vertical: true)
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
                    title: "Import Scrivener Project",
                    systemImage: "square.and.arrow.down",
                    action: { isShowingScrivenerImporter = true }
                )
            }
        }
        .padding(.bottom, 8)
        #endif
    }
    
    private var recentDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent Projects")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    recentDocumentsManager.clearRecentDocuments()
                } label: {
                    Text("Clear All")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            #if os(macOS)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

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

                        Button(action: {
                            NSWorkspace.shared.selectFile(document.url.path, inFileViewerRootedAtPath: document.url.deletingLastPathComponent().path)
                        }) {
                            Label("Show in Finder", systemImage: "folder")
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
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Templates")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Start with a proven story structure. Each template provides acts, chapters, and scenes based on classic storytelling frameworks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    if let url = URL(string: "https://manuscriptapp.github.io/manuscript/#features") {
                        #if os(macOS)
                        NSWorkspace.shared.open(url)
                        #else
                        UIApplication.shared.open(url)
                        #endif
                    }
                } label: {
                    Text("How it works")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }

            #if os(macOS)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    BlankTemplateCard {
                        isShowingNewProjectSheet = true
                    }
                    .frame(width: 100)

                    ForEach(shuffledTemplates, id: \.id) { template in
                        TemplateCardView(template: template)
                            .frame(width: 100)
                            .onTapGesture {
                                templateToShow = template
                            }
                    }
                }
                .padding(.vertical, 4)
            }
            #else
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

            LazyVGrid(columns: columns, spacing: 12) {
                BlankTemplateCard {
                    isShowingNewProjectSheet = true
                }

                ForEach(shuffledTemplates, id: \.id) { template in
                    TemplateCardView(template: template)
                        .onTapGesture {
                            templateToShow = template
                        }
                }
            }
            #endif
        }
    }

    private var footerSection: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.top, 12)

            HStack(spacing: 24) {
                Button {
                    if let url = URL(string: "https://github.com/manuscriptapp/manuscript") {
                        #if os(macOS)
                        NSWorkspace.shared.open(url)
                        #else
                        UIApplication.shared.open(url)
                        #endif
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 12))
                        Text("View on GitHub")
                            .font(.footnote)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    if let url = URL(string: "https://manuscriptapp.github.io/manuscript") {
                        #if os(macOS)
                        NSWorkspace.shared.open(url)
                        #else
                        UIApplication.shared.open(url)
                        #endif
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                        Text("Website")
                            .font(.footnote)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text("Open source · MPL-2.0")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Helper Views

    private func quickActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.tint)
                    .frame(width: 26, height: 26)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.06))
            )
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

    private var isCloudDocument: Bool {
        let path = document.url.path
        return path.contains("Mobile Documents") ||
               path.contains("com~apple~CloudDocs") ||
               path.contains("iCloud")
    }

    private var relativeDate: String {
        let now = Date()
        let date = document.lastOpenedDate
        let interval = now.timeIntervalSince(date)

        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes) min ago"
        } else if hours < 24 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if days < 7 {
            return days == 1 ? "Yesterday" : "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: isCloudDocument ? "icloud" : "folder")
                            .font(.system(size: 9))
                            .foregroundStyle(isCloudDocument ? .blue : .secondary)

                        Text(relativeDate)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}

struct BlankTemplateCard: View {
    let action: () -> Void

    private let bookColor = Color(red: 0.5, green: 0.5, blue: 0.53)

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // Main cover
                RoundedRectangle(cornerRadius: 3)
                    .fill(bookColor)

                // Spine edge effect
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(.black.opacity(0.15))
                        .frame(width: 6)
                    Spacer()
                }

                // Content on cover
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("Blank Book")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Start fresh")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.leading, 12)
                .padding(.trailing, 10)
                .padding(.vertical, 10)
            }
            .aspectRatio(0.7, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 2)
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
