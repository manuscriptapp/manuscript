import SwiftUI
import SwiftData

/// View mode for displaying folder contents
enum FolderViewMode: String, CaseIterable {
    case grid
    case corkboard
    case outline

    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .corkboard: return "rectangle.on.rectangle"
        case .outline: return "list.bullet.indent"
        }
    }

    var label: String {
        switch self {
        case .grid: return "Grid"
        case .corkboard: return "Corkboard"
        case .outline: return "Outline"
        }
    }
}

struct FolderDetailView: View {
    let folder: ManuscriptFolder
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?
    @AppStorage("folderViewMode") private var viewMode: FolderViewMode = .grid

    var body: some View {
        Group {
            switch viewMode {
            case .grid:
                gridView
            case .corkboard:
                CorkboardView(folderId: folder.id, viewModel: viewModel, selection: $selection)
            case .outline:
                OutlineView(folderId: folder.id, viewModel: viewModel, selection: $selection)
            }
        }
        .navigationTitle(folder.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    viewModeToggle
                    addDocumentButton
                }
            }
        }
        .onAppear {
            viewModel.navigateToFolder(folder)
        }
    }

    private var viewModeToggle: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(FolderViewMode.allCases, id: \.self) { mode in
                Label(mode.label, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 120)
    }

    private var addDocumentButton: some View {
        Button {
            viewModel.addDocument(to: folder, title: "New Document")
        } label: {
            Label("Add Document", systemImage: "plus")
        }
    }

    private var gridView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Subfolders section
                if !folder.subfolders.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Folders")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                            ForEach(folder.subfolders) { subfolder in
                                FolderCard(folder: subfolder, viewModel: viewModel, selection: $selection)
                                    .frame(height: 120)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Documents section
                if !folder.documents.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        if !folder.subfolders.isEmpty {
                            Text("Documents")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                            ForEach(folder.documents) { document in
                                FolderDocumentCard(document: document, viewModel: viewModel, selection: $selection)
                                    .frame(height: 220)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Empty state
                if folder.subfolders.isEmpty && folder.documents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("This folder is empty")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add documents or subfolders to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.vertical)
        }
    }
}

struct FolderCard: View {
    let folder: ManuscriptFolder
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    var body: some View {
        Button {
            // Expand ancestors so this folder is visible in sidebar
            viewModel.expandToFolder(folder)
            selection = .folder(folder)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text(folder.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                }

                Spacer()

                HStack {
                    if !folder.subfolders.isEmpty {
                        Label("\(folder.subfolders.count)", systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !folder.documents.isEmpty {
                        Label("\(folder.documents.count)", systemImage: "doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                // TODO: Implement rename for folders
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                // TODO: Implement delete for folders
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct FolderDocumentCard: View {
    let document: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    var body: some View {
        Button {
            // Expand ancestors so document's folder is visible in sidebar
            viewModel.expandToDocument(document)
            // Select the document in the sidebar
            selection = .document(document)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: document.iconName)
                        .foregroundColor(colorForDocument(document))
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(1)
                }

                Divider()

                Text(document.synopsis.isEmpty ? "No synopsis" : document.synopsis)
                    .font(.caption)
                    .lineLimit(5)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Created: \(document.creationDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                viewModel.showRenameAlert(for: document)
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                viewModel.deleteDocument(document)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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
        return colorMap[document.colorName] ?? .primary
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: DetailSelection? = nil
    FolderDetailView(
        folder: ManuscriptFolder(id: UUID(), title: "Test Folder", creationDate: Date(), order: 0),
        viewModel: DocumentViewModel(),
        selection: $selection
    )
}
#endif
