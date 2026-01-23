import SwiftUI

/// Sort columns for the outline view
enum OutlineSortColumn: String, CaseIterable {
    case title
    case label
    case status
    case keywords
    case words

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .label: return "Label"
        case .status: return "Status"
        case .keywords: return "Keywords"
        case .words: return "Words"
        }
    }
}

/// Outline view displaying folder contents in a sortable table format
struct OutlineView: View {
    let folderId: UUID
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    @AppStorage("outlineSortColumn") private var sortColumn: OutlineSortColumn = .title
    @AppStorage("outlineSortAscending") private var sortAscending: Bool = true

    /// Use currentFolder from viewModel - it's @Published so changes trigger updates
    private var folder: ManuscriptFolder {
        if viewModel.currentFolder.id == folderId {
            return viewModel.currentFolder
        }
        return viewModel.findFolder(withId: folderId, in: viewModel.document.rootFolder)
            ?? viewModel.currentFolder
    }

    private var sortedSubfolders: [ManuscriptFolder] {
        folder.subfolders.sorted { $0.order < $1.order }
    }

    private var sortedDocuments: [ManuscriptDocument.Document] {
        let documents = folder.documents

        let sorted: [ManuscriptDocument.Document]
        switch sortColumn {
        case .title:
            sorted = documents.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .label:
            sorted = documents.sorted { labelName(for: $0).localizedCompare(labelName(for: $1)) == .orderedAscending }
        case .status:
            sorted = documents.sorted { statusName(for: $0).localizedCompare(statusName(for: $1)) == .orderedAscending }
        case .keywords:
            sorted = documents.sorted { $0.keywords.joined().localizedCompare($1.keywords.joined()) == .orderedAscending }
        case .words:
            sorted = documents.sorted { $0.wordCount < $1.wordCount }
        }

        return sortAscending ? sorted : sorted.reversed()
    }

    private func labelName(for document: ManuscriptDocument.Document) -> String {
        guard let labelId = document.labelId,
              let label = viewModel.document.labels.first(where: { $0.id == labelId }) else {
            return ""
        }
        return label.name
    }

    private func statusName(for document: ManuscriptDocument.Document) -> String {
        guard let statusId = document.statusId,
              let status = viewModel.document.statuses.first(where: { $0.id == statusId }) else {
            return ""
        }
        return status.name
    }

    var body: some View {
        let orderKey = sortedDocuments.map { "\($0.id.uuidString.prefix(8)):\($0.order)" }.joined()

        VStack(spacing: 0) {
            // Header row
            OutlineHeaderView(
                sortColumn: $sortColumn,
                sortAscending: $sortAscending
            )

            Divider()

            if sortedSubfolders.isEmpty && sortedDocuments.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("This folder is empty")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add documents or subfolders to see them in the outline")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Subfolders
                        ForEach(sortedSubfolders) { subfolder in
                            OutlineFolderRow(
                                folder: subfolder,
                                viewModel: viewModel,
                                selection: $selection
                            )
                            .dropDestination(for: DraggableSidebarItem.self) { items, _ in
                                handleFolderDrop(items: items, targetFolderId: subfolder.id)
                            }
                            Divider()
                        }

                        // Documents
                        ForEach(Array(sortedDocuments.enumerated()), id: \.element.id) { index, document in
                            OutlineRowView(
                                document: document,
                                viewModel: viewModel,
                                selection: $selection
                            )
                            .draggable(DraggableSidebarItem(id: document.id, itemType: .document))
                            .dropDestination(for: DraggableSidebarItem.self) { items, _ in
                                handleDocumentDrop(items: items, targetIndex: index, sortedDocuments: sortedDocuments)
                            }
                            Divider()
                        }
                    }
                }
            }
        }
        .id(orderKey)
    }

    /// Handle dropping items onto a folder row (move document into folder)
    private func handleFolderDrop(items: [DraggableSidebarItem], targetFolderId: UUID) -> Bool {
        guard let item = items.first else { return false }

        if item.itemType == .document {
            viewModel.moveDocumentToFolder(item.id, targetFolderId: targetFolderId)
            return true
        }

        return false
    }

    /// Handle dropping items onto a document row (reorder)
    private func handleDocumentDrop(items: [DraggableSidebarItem], targetIndex: Int, sortedDocuments: [ManuscriptDocument.Document]) -> Bool {
        guard let item = items.first, item.itemType == .document else { return false }

        guard let folder = viewModel.findFolder(withId: folderId, in: viewModel.document.rootFolder) else {
            return false
        }

        guard targetIndex < sortedDocuments.count else { return false }
        let targetDocument = sortedDocuments[targetIndex]

        guard let sourceIndex = folder.documents.firstIndex(where: { $0.id == item.id }) else {
            return false
        }

        guard let targetOriginalIndex = folder.documents.firstIndex(where: { $0.id == targetDocument.id }) else {
            return false
        }

        if sourceIndex == targetOriginalIndex { return false }

        let destination = sourceIndex < targetOriginalIndex ? targetOriginalIndex + 1 : targetOriginalIndex

        viewModel.moveDocuments(in: folder, from: IndexSet(integer: sourceIndex), to: destination)
        return true
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: DetailSelection? = nil
    OutlineView(
        folderId: UUID(),
        viewModel: DocumentViewModel(),
        selection: $selection
    )
}
#endif
