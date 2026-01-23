import SwiftUI

/// Folder row in the outline view - simpler than document rows
struct OutlineFolderRow: View {
    let folder: ManuscriptFolder
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    @State private var isHovered = false

    private var isSelected: Bool {
        if case .folder(let selected) = selection {
            return selected.id == folder.id
        }
        return false
    }

    var body: some View {
        Button {
            viewModel.expandToFolder(folder)
            selection = .folder(folder)
        } label: {
            HStack(spacing: 0) {
                // Folder icon and title (flexible)
                HStack(spacing: 8) {
                    Image(systemName: folder.iconName)
                        .foregroundColor(iconColor)
                        .frame(width: 16)

                    Text(folder.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()
                }
                .frame(minWidth: 200, alignment: .leading)

                // Subfolder count
                if !folder.subfolders.isEmpty {
                    Label("\(folder.subfolders.count)", systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                } else {
                    Spacer()
                        .frame(width: 60)
                }

                // Document count
                if !folder.documents.isEmpty {
                    Label("\(folder.documents.count)", systemImage: "doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                } else {
                    Spacer()
                        .frame(width: 60)
                }

                Spacer()

                // Total word count
                Text("\(folder.totalWordCount)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button {
                viewModel.showRenameAlert(for: folder)
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            if folder.id != viewModel.document.rootFolder.id {
                Divider()

                Button(role: .destructive) {
                    viewModel.deleteFolder(folder)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var iconColor: Color {
        if let hexColor = folder.iconColor, let color = Color(hex: hexColor) {
            return color
        }
        return .cyan
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.2)
        } else if isHovered {
            return Color.secondary.opacity(0.1)
        }
        return Color.blue.opacity(0.05)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: DetailSelection? = nil
    OutlineFolderRow(
        folder: ManuscriptFolder(title: "Chapter 1"),
        viewModel: DocumentViewModel(),
        selection: $selection
    )
}
#endif
