import SwiftUI

/// Icon that turns white when background prominence is increased (focused selection)
private struct AdaptiveFolderIcon: View {
    let systemName: String
    let defaultColor: Color
    @Environment(\.backgroundProminence) private var backgroundProminence

    var body: some View {
        Image(systemName: systemName)
            .foregroundStyle(backgroundProminence == .increased ? .white : defaultColor)
    }
}

struct FolderItemView: View {
    let folder: ManuscriptFolder
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var detailSelection: DetailSelection?

    private struct RecursiveFolderView: View {
        let folderId: UUID
        @ObservedObject var viewModel: DocumentViewModel
        @Binding var detailSelection: DetailSelection?
        @State private var isAddFolderSheetPresented = false
        @State private var isAddMediaSheetPresented = false
        @State private var isImportDocumentSheetPresented = false

        /// Look up the current folder from all folder hierarchies to ensure we always have fresh data
        private var folder: ManuscriptFolder {
            viewModel.findFolderInAllFolders(withId: folderId) ?? ManuscriptFolder(title: "Unknown")
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

        @ViewBuilder
        private func menuActionLabel(_ title: String, systemImage: String) -> some View {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.accentColor)
            }
        }

        /// Returns the base icon color for the folder
        private func baseIconColor(for folder: ManuscriptFolder) -> Color {
            // Use icon-specific color if available
            if let hexColor = folder.iconColor, let color = Color(hex: hexColor) {
                return color
            }
            // Default to brown accent
            return .brown
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

                // Media items in this folder (sorted by order)
                ForEach(folder.mediaItems.sorted { $0.order < $1.order }) { mediaItem in
                    MediaItemView(
                        mediaItem: mediaItem,
                        viewModel: viewModel,
                        selection: $detailSelection
                    )
                    .tag(DetailSelection.mediaItem(mediaItem))
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
                    AdaptiveFolderIcon(systemName: folder.iconName, defaultColor: baseIconColor(for: folder))
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
                        isAddFolderSheetPresented = true
                    }) {
                        menuActionLabel("Add Folder", systemImage: "folder.badge.plus")
                    }

                    Button(action: {
                        viewModel.addUntitledDocument(to: folder)
                    }) {
                        menuActionLabel("Add Document", systemImage: "doc.badge.plus")
                    }

                    Button(action: {
                        isAddMediaSheetPresented = true
                    }) {
                        menuActionLabel("Add Media", systemImage: "photo.badge.plus")
                    }

                    Button(action: {
                        isImportDocumentSheetPresented = true
                    }) {
                        menuActionLabel("Import Document...", systemImage: "square.and.arrow.down")
                    }

                    Divider()

                    Button(action: {
                        viewModel.showRenameAlert(for: folder)
                    }) {
                        menuActionLabel("Rename Folder", systemImage: "pencil")
                    }

                    // Trash folder gets "Empty Trash" option
                    if folder.folderType == .trash {
                        Button(role: .destructive, action: {
                            viewModel.showEmptyTrashConfirmation = true
                        }) {
                            Label("Empty Trash", systemImage: "trash.slash")
                        }
                        .disabled(folder.isEmpty)
                    } else if viewModel.isFolderInTrash(folder) {
                        // Folders inside trash get restore/permanent delete options
                        Button(action: {
                            viewModel.restoreFolderFromTrash(folder)
                        }) {
                            menuActionLabel("Restore", systemImage: "arrow.uturn.backward")
                        }

                        Button(role: .destructive, action: {
                            viewModel.permanentlyDeleteFolder(folder)
                        }) {
                            Label("Delete Permanently", systemImage: "trash.slash")
                        }
                    } else if folder.id != viewModel.rootFolder.id && folder.id != viewModel.researchFolder.id {
                        // Normal folders get move to trash option
                        Button(role: .destructive, action: {
                            viewModel.moveFolderToTrash(folder)
                        }) {
                            Label("Move to Trash", systemImage: "trash")
                        }
                    }
                }
                #else
                .contextMenu {
                    Button(action: {
                        detailSelection = .folder(folder)
                    }) {
                        menuActionLabel("View Details", systemImage: "info.circle")
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
                        menuActionLabel("Add Folder", systemImage: "folder.badge.plus")
                    }

                    Button(action: {
                        viewModel.addUntitledDocument(to: folder)
                    }) {
                        menuActionLabel("Add Document", systemImage: "doc.badge.plus")
                    }

                    Button(action: {
                        isAddMediaSheetPresented = true
                    }) {
                        menuActionLabel("Add Media", systemImage: "photo.badge.plus")
                    }

                    Button(action: {
                        isImportDocumentSheetPresented = true
                    }) {
                        menuActionLabel("Import Document...", systemImage: "square.and.arrow.down")
                    }

                    Divider()

                    Button(action: {
                        viewModel.showRenameAlert(for: folder)
                    }) {
                        menuActionLabel("Rename Folder", systemImage: "pencil")
                    }

                    // Trash folder gets "Empty Trash" option
                    if folder.folderType == .trash {
                        Button(role: .destructive, action: {
                            viewModel.showEmptyTrashConfirmation = true
                        }) {
                            Label("Empty Trash", systemImage: "trash.slash")
                        }
                        .disabled(folder.isEmpty)
                    } else if viewModel.isFolderInTrash(folder) {
                        // Folders inside trash get restore/permanent delete options
                        Button(action: {
                            viewModel.restoreFolderFromTrash(folder)
                        }) {
                            menuActionLabel("Restore", systemImage: "arrow.uturn.backward")
                        }

                        Button(role: .destructive, action: {
                            viewModel.permanentlyDeleteFolder(folder)
                        }) {
                            Label("Delete Permanently", systemImage: "trash.slash")
                        }
                    } else if folder.id != viewModel.rootFolder.id && folder.id != viewModel.researchFolder.id {
                        // Normal folders get move to trash option
                        Button(role: .destructive, action: {
                            viewModel.moveFolderToTrash(folder)
                        }) {
                            Label("Move to Trash", systemImage: "trash")
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    if folder.folderType == .trash {
                        Button(role: .destructive, action: {
                            viewModel.showEmptyTrashConfirmation = true
                        }) {
                            Label("Empty", systemImage: "trash.slash")
                        }
                        .disabled(folder.isEmpty)
                    } else if viewModel.isFolderInTrash(folder) {
                        Button(role: .destructive, action: {
                            viewModel.permanentlyDeleteFolder(folder)
                        }) {
                            Label("Delete", systemImage: "trash.slash")
                        }

                        Button {
                            viewModel.restoreFolderFromTrash(folder)
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.green)
                    } else if folder.id != viewModel.rootFolder.id && folder.id != viewModel.researchFolder.id {
                        Button(action: {
                            viewModel.showRenameAlert(for: folder)
                        }) {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.accentColor)

                        Button(role: .destructive, action: {
                            viewModel.moveFolderToTrash(folder)
                        }) {
                            Label("Trash", systemImage: "trash")
                        }
                    } else {
                        Button(action: {
                            viewModel.showRenameAlert(for: folder)
                        }) {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.accentColor)
                    }
                }
                #endif
                .sheet(isPresented: $isAddFolderSheetPresented) {
                    AddFolderSheet(
                        viewModel: viewModel,
                        initialFolder: folder
                    )
                }
                .sheet(isPresented: $isAddMediaSheetPresented) {
                    AddMediaSheet(
                        viewModel: viewModel,
                        targetFolder: folder
                    )
                }
                .sheet(isPresented: $isImportDocumentSheetPresented) {
                    DocumentImportView(targetFolder: folder) { importedDocument in
                        viewModel.addImportedDocument(to: folder, importedDocument: importedDocument)
                    }
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
