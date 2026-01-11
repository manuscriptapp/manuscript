import SwiftUI
import SwiftData

struct FolderDetailView: View {
    let folder: ManuscriptFolder
    @ObservedObject var viewModel: DocumentViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                ForEach(folder.documents) { document in
                    FolderDocumentCard(document: document, viewModel: viewModel)
                        .frame(height: 220)
                }
            }
            .padding()
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
    FolderDetailView(
        folder: ManuscriptFolder(id: UUID(), title: "Test Folder", creationDate: Date(), order: 0),
        viewModel: DocumentViewModel()
    )
}
#endif
