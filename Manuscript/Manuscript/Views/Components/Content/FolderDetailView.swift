import SwiftUI
import SwiftData

struct FolderDetailView: View {
    let folder: ManuscriptFolder
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    var body: some View {
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
                                FolderDocumentCard(document: document, viewModel: viewModel)
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
        .navigationTitle(folder.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.addDocument(to: folder, title: "New Document")
                } label: {
                    Label("Add Document", systemImage: "plus")
                }
            }
        }
        .onAppear {
            viewModel.navigateToFolder(folder)
        }
    }
}

struct FolderCard: View {
    let folder: ManuscriptFolder
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    var body: some View {
        Button {
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

    var body: some View {
        Button {
            viewModel.selectDocument(document)
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

                Text(document.outline.isEmpty ? "No outline" : document.outline)
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
