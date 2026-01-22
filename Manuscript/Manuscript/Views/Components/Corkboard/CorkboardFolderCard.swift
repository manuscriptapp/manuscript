import SwiftUI

/// Index card view for folders in corkboard mode
struct CorkboardFolderCard: View {
    let folder: ManuscriptFolder
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    private var isSelected: Bool {
        if case .folder(let f) = selection {
            return f.id == folder.id
        }
        return false
    }

    var body: some View {
        Button {
            viewModel.expandToFolder(folder)
            selection = .folder(folder)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header bar with folder icon and title
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)

                    Text(folder.title)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.15))

                Divider()

                // Content area showing counts
                VStack(alignment: .leading, spacing: 8) {
                    if folder.subfolders.isEmpty && folder.documents.isEmpty {
                        Text("Empty folder")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        if !folder.subfolders.isEmpty {
                            Label("\(folder.subfolders.count) subfolder\(folder.subfolders.count == 1 ? "" : "s")", systemImage: "folder")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        if !folder.documents.isEmpty {
                            Label("\(folder.documents.count) document\(folder.documents.count == 1 ? "" : "s")", systemImage: "doc.text")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Divider()

                // Footer
                HStack {
                    Text(totalWordCount > 0 ? "\(totalWordCount.formatted()) words" : "No content")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .draggable(DraggableSidebarItem(id: folder.id, itemType: .folder))
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

    private var cardBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    /// Calculate total word count for all documents in this folder (not recursive)
    private var totalWordCount: Int {
        folder.documents.reduce(0) { $0 + $1.wordCount }
    }
}
