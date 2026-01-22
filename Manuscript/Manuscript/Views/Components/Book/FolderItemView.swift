import SwiftUI

struct FolderItemView: View {
    let folder: ManuscriptFolder
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var detailSelection: DetailSelection?

    private struct RecursiveFolderView: View {
        let folderId: UUID
        @ObservedObject var viewModel: DocumentViewModel
        @Binding var detailSelection: DetailSelection?
        @State private var isAddFolderSheetPresented = false

        /// Look up the current folder from the published rootFolder to ensure we always have fresh data
        private var folder: ManuscriptFolder {
            findFolder(withId: folderId, in: viewModel.rootFolder) ?? ManuscriptFolder(title: "Unknown")
        }

        private func findFolder(withId id: UUID, in searchFolder: ManuscriptFolder) -> ManuscriptFolder? {
            if searchFolder.id == id { return searchFolder }
            for subfolder in searchFolder.subfolders {
                if let found = findFolder(withId: id, in: subfolder) {
                    return found
                }
            }
            return nil
        }

        // Icon options for folders
        private let iconOptions: [(String, String)] = [
            ("Folder", "folder"),
            ("Book", "book.closed"),
            ("Draft", "doc.text"),
            ("Notes", "note.text"),
            ("Ideas", "lightbulb"),
            ("Characters", "person.2"),
            ("Locations", "mappin.and.ellipse"),
            ("Research", "magnifyingglass"),
            ("Scenes", "theatermasks"),
            ("Timeline", "clock"),
            ("Archive", "archivebox"),
            ("Trash", "trash"),
            ("Star", "star"),
            ("Heart", "heart"),
            ("Flag", "flag"),
            ("Bookmark", "bookmark")
        ]

        // Color options
        private let colorOptions: [(String, Color, String)] = [
            ("Yellow", .yellow, "#FFD60A"),
            ("Mint", .mint, "#00C7BE"),
            ("Pink", .pink, "#FF2D55"),
            ("Orange", .orange, "#FF9500"),
            ("Teal", .teal, "#30B0C7"),
            ("Purple", .purple, "#AF52DE"),
            ("Green", .green, "#34C759"),
            ("Blue", .blue, "#007AFF"),
            ("Red", .red, "#FF3B30"),
            ("Brown", .brown, "#A2845E"),
            ("Default", .secondary, "")
        ]

        // Computed binding to the view model's expansion state
        private var isExpanded: Binding<Bool> {
            Binding(
                get: { viewModel.isFolderExpanded(folder) },
                set: { viewModel.setFolderExpanded(folder, expanded: $0) }
            )
        }

        init(folderId: UUID, viewModel: DocumentViewModel, detailSelection: Binding<DetailSelection?>) {
            self.folderId = folderId
            self.viewModel = viewModel
            self._detailSelection = detailSelection
        }

        private func updateFolderIcon(_ iconName: String) {
            viewModel.updateFolderIcon(folder, iconName: iconName)
        }

        private func updateFolderColor(_ hexColor: String?) {
            viewModel.updateFolderIconColor(folder, hexColor: hexColor?.isEmpty == true ? nil : hexColor)
        }

        /// Returns the icon color for the folder
        private func iconColorForFolder(_ folder: ManuscriptFolder) -> Color {
            // Use icon-specific color if available
            if let hexColor = folder.iconColor, let color = Color(hex: hexColor) {
                return isFolderSelected(folder) ? color.darker(by: 0.3) : color
            }
            // Fallback to dominant color or accent for root
            let baseColor = dominantColor(for: folder)
            return isFolderSelected(folder) ? baseColor.darker(by: 0.3) : baseColor
        }

        private func colorForDocument(_ document: ManuscriptDocument.Document) -> Color {
            let colorMap: [String: Color] = [
                "Yellow": .yellow,
                "Mint": .mint,
                "Pink": .pink,
                "Orange": .orange,
                "Teal": .teal,
                "Purple": .purple,
                "Green": .green,
                "Blue": .blue,
                "Red": .red,
                "Brown": .brown
            ]
            return colorMap[document.colorName] ?? .brown
        }
        
        private func dominantColor(for folder: ManuscriptFolder) -> Color {
            // If it's the root folder, use accent color
            if folder.id == viewModel.rootFolder.id {
                return .accent
            }
            
            // Get all documents in this folder and subfolders
            var allDocuments = folder.documents
            for subfolder in folder.subfolders {
                allDocuments.append(contentsOf: subfolder.documents)
            }
            
            // If no documents, use secondary color
            if allDocuments.isEmpty {
                return .secondary
            }
            
            // Count occurrences of each color
            var colorCounts: [Color: Int] = [:]
            for document in allDocuments {
                let color = colorForDocument(document)
                colorCounts[color, default: 0] += 1
            }
            
            // Return the most common color, or secondary if no colors found
            return colorCounts.max(by: { $0.value < $1.value })?.key ?? .secondary
        }
        
        // Helper computed property to check if this folder is selected
        private func isFolderSelected(_ folder: ManuscriptFolder) -> Bool {
            if case .folder(let selectedFolder) = detailSelection, selectedFolder.id == folder.id {
                return true
            }
            return false
        }
        
        var body: some View {
            DisclosureGroup(isExpanded: isExpanded) {
                // Documents in this folder (sorted by order)
                ForEach(folder.documents.sorted { $0.order < $1.order }) { document in
                    DocumentItemView(
                        documentId: document.id,
                        viewModel: viewModel,
                        detailSelection: $detailSelection
                    )
                }
                .onMove { source, destination in
                    viewModel.moveDocuments(in: folder, from: source, to: destination)
                }

                // Subfolders (sorted by order)
                ForEach(folder.subfolders.sorted { $0.order < $1.order }) { subfolder in
                    RecursiveFolderView(
                        folderId: subfolder.id,
                        viewModel: viewModel,
                        detailSelection: $detailSelection
                    )
                }
                .onMove { source, destination in
                    viewModel.moveSubfolders(in: folder, from: source, to: destination)
                }
            } label: {
                Label {
                    Text(folder.title)
                } icon: {
                    Image(systemName: folder.iconName)
                        .foregroundStyle(iconColorForFolder(folder))
                }
                .id("\(folderId)-\(folder.iconName)-\(folder.iconColor ?? "")")
                .badge(folder.totalDocumentCount)
                .tag(DetailSelection.folder(folder))
                .draggable(DraggableSidebarItem(id: folder.id, itemType: .folder)) {
                    Label(folder.title, systemImage: folder.iconName)
                }
                .dropDestination(for: DraggableSidebarItem.self) { items, _ in
                    for item in items {
                        switch item.itemType {
                        case .document:
                            viewModel.moveDocumentToFolder(item.id, targetFolderId: folder.id)
                        case .folder:
                            viewModel.moveFolderToParent(item.id, targetParentId: folder.id)
                        }
                    }
                    return !items.isEmpty
                }
                #if os(macOS)
                .contextMenu {
                    Menu("Change Icon") {
                        ForEach(iconOptions, id: \.0) { name, icon in
                            Button(action: { updateFolderIcon(icon) }) {
                                Label(name, systemImage: icon)
                            }
                        }
                    }

                    Menu("Change Color") {
                        ForEach(colorOptions, id: \.0) { name, color, hex in
                            Button(action: { updateFolderColor(hex.isEmpty ? nil : hex) }) {
                                HStack {
                                    Image(systemName: folder.iconColor == hex || (folder.iconColor == nil && hex.isEmpty) ? "checkmark.circle.fill" : "circle.fill")
                                        .foregroundColor(color)
                                    Text(name)
                                }
                            }
                        }
                    }

                    Divider()

                    Button(action: {
                        viewModel.showRenameAlert(for: folder)
                    }) {
                        Label("Rename Folder", systemImage: "pencil")
                    }

                    if folder.id != viewModel.rootFolder.id {
                        Button(role: .destructive, action: {
                            viewModel.deleteFolder(folder)
                        }) {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }
                #else
                .contextMenu {
                    Button(action: {
                        detailSelection = .folder(folder)
                    }) {
                        Label("View Details", systemImage: "info.circle")
                    }

                    Menu("Change Icon") {
                        ForEach(iconOptions, id: \.0) { name, icon in
                            Button(action: { updateFolderIcon(icon) }) {
                                Label(name, systemImage: icon)
                            }
                        }
                    }

                    Menu("Change Color") {
                        ForEach(colorOptions, id: \.0) { name, color, hex in
                            Button(action: { updateFolderColor(hex.isEmpty ? nil : hex) }) {
                                HStack {
                                    Image(systemName: folder.iconColor == hex || (folder.iconColor == nil && hex.isEmpty) ? "checkmark.circle.fill" : "circle.fill")
                                        .foregroundColor(color)
                                    Text(name)
                                }
                            }
                        }
                    }

                    Divider()

                    Button(action: {
                        isAddFolderSheetPresented = true
                    }) {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }

                    Button(action: {
                        viewModel.addUntitledDocument(to: folder)
                    }) {
                        Label("Add Document", systemImage: "doc.badge.plus")
                    }

                    Divider()

                    Button(action: {
                        viewModel.showRenameAlert(for: folder)
                    }) {
                        Label("Rename Folder", systemImage: "pencil")
                    }

                    if folder.id != viewModel.rootFolder.id {
                        Button(role: .destructive, action: {
                            viewModel.deleteFolder(folder)
                        }) {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(action: {
                        viewModel.showRenameAlert(for: folder)
                    }) {
                        Label("Rename Folder", systemImage: "pencil")
                    }
                    .tint(.blue)

                    if folder.id != viewModel.rootFolder.id {
                        Button(role: .destructive, action: {
                            viewModel.deleteFolder(folder)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                #endif
                .sheet(isPresented: $isAddFolderSheetPresented) {
                    AddFolderSheet(
                        viewModel: viewModel,
                        initialFolder: folder
                    )
                }
            }
        }
    }
    
    var body: some View {
        RecursiveFolderView(
            folderId: folder.id,
            viewModel: viewModel,
            detailSelection: $detailSelection
        )
    }
}

// Extension to make colors darker - needed for the UI
extension Color {
    func darker(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
}

