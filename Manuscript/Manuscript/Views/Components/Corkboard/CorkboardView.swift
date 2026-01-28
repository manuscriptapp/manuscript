import SwiftUI

/// Corkboard view displaying documents and folders as index cards in a grid
struct CorkboardView: View {
    let folderId: UUID
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    /// Use currentFolder from viewModel - it's @Published so changes trigger updates
    private var folder: ManuscriptFolder {
        // If currentFolder matches our folderId, use it (it's @Published and updates)
        // Otherwise fall back to looking it up
        if viewModel.currentFolder.id == folderId {
            return viewModel.currentFolder
        }
        return viewModel.findFolder(withId: folderId, in: viewModel.document.rootFolder)
            ?? viewModel.currentFolder
    }

    var body: some View {
        let sortedSubfolders = folder.subfolders.sorted { $0.order < $1.order }
        let sortedDocuments = folder.documents.sorted { $0.order < $1.order }

        // Create a unique ID based on document order to force view refresh
        let orderKey = sortedDocuments.map { "\($0.id.uuidString.prefix(8)):\($0.order)" }.joined()

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Subfolders section
                if !sortedSubfolders.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        CorkboardSectionLabel(title: "Folders")
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 16) {
                            ForEach(sortedSubfolders) { subfolder in
                                CorkboardFolderCard(
                                    folder: subfolder,
                                    viewModel: viewModel,
                                    selection: $selection
                                )
                                .frame(height: 160)
                                .dropDestination(for: DraggableSidebarItem.self) { items, _ in
                                    handleFolderDrop(items: items, targetFolderId: subfolder.id)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Documents section
                if !sortedDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        if !sortedSubfolders.isEmpty {
                            CorkboardSectionLabel(title: "Documents")
                                .padding(.horizontal)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 16) {
                            ForEach(Array(sortedDocuments.enumerated()), id: \.element.id) { index, document in
                                CorkboardCardView(
                                    document: document,
                                    viewModel: viewModel,
                                    selection: $selection
                                )
                                .frame(height: 200)
                                .dropDestination(for: DraggableSidebarItem.self) { items, _ in
                                    handleDocumentDrop(items: items, targetIndex: index, sortedDocuments: sortedDocuments)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Empty state
                if sortedSubfolders.isEmpty && sortedDocuments.isEmpty {
                    CorkboardEmptyState()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                }
            }
            .padding(.vertical)
        }
        .id(orderKey)
        .background(CorkboardBackground())
    }

    /// Handle dropping items onto a folder card (move document into folder)
    private func handleFolderDrop(items: [DraggableSidebarItem], targetFolderId: UUID) -> Bool {
        guard let item = items.first else { return false }

        if item.itemType == .document {
            viewModel.moveDocumentToFolder(item.id, targetFolderId: targetFolderId)
            return true
        }

        return false
    }

    /// Handle dropping items onto a document card (reorder)
    private func handleDocumentDrop(items: [DraggableSidebarItem], targetIndex: Int, sortedDocuments: [ManuscriptDocument.Document]) -> Bool {
        guard let item = items.first, item.itemType == .document else { return false }

        // Get the current folder fresh from viewModel
        guard let folder = viewModel.findFolder(withId: folderId, in: viewModel.document.rootFolder) else {
            return false
        }

        // Get the target document from sorted array
        guard targetIndex < sortedDocuments.count else { return false }
        let targetDocument = sortedDocuments[targetIndex]

        // Find source index in the ORIGINAL folder.documents array (not sorted)
        guard let sourceIndex = folder.documents.firstIndex(where: { $0.id == item.id }) else {
            return false
        }

        // Find target index in the ORIGINAL folder.documents array
        guard let targetOriginalIndex = folder.documents.firstIndex(where: { $0.id == targetDocument.id }) else {
            return false
        }

        // Don't move if dropping on itself
        if sourceIndex == targetOriginalIndex { return false }

        // Calculate destination for move operation
        let destination = sourceIndex < targetOriginalIndex ? targetOriginalIndex + 1 : targetOriginalIndex

        viewModel.moveDocuments(in: folder, from: IndexSet(integer: sourceIndex), to: destination)
        return true
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: DetailSelection? = nil
    CorkboardView(
        folderId: UUID(),
        viewModel: DocumentViewModel(),
        selection: $selection
    )
}
#endif
