import SwiftUI

/// Document row in the outline view
struct OutlineRowView: View {
    let document: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    @State private var isHovered = false

    private var isSelected: Bool {
        if case .document(let selected) = selection {
            return selected.id == document.id
        }
        return false
    }

    var body: some View {
        Button {
            viewModel.expandToDocument(document)
            selection = .document(document)
        } label: {
            HStack(spacing: 0) {
                // Title & Synopsis column (flexible)
                titleCell
                    .frame(minWidth: 200, alignment: .leading)

                // Label column (fixed)
                OutlineLabelPicker(document: document, viewModel: viewModel)
                    .frame(width: 100)

                // Status column (fixed)
                OutlineStatusPicker(document: document, viewModel: viewModel)
                    .frame(width: 100)

                // Keywords column (fixed)
                OutlineKeywordsView(keywords: document.keywords)
                    .frame(width: 120)

                // Words column (fixed)
                Text("\(document.wordCount)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button {
                viewModel.showRenameAlert(for: document)
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                viewModel.deleteDocument(document)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var titleCell: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: document.iconName)
                .foregroundColor(iconColor)
                .frame(width: 16)

            // Title and synopsis
            VStack(alignment: .leading, spacing: 2) {
                Text(document.title.isEmpty ? "Untitled" : document.title)
                    .font(.body)
                    .lineLimit(1)

                if !document.outline.isEmpty {
                    Text(document.outline)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
    }

    private var iconColor: Color {
        if let hexColor = document.iconColor, let color = Color(hex: hexColor) {
            return color
        }
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

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.2)
        } else if isHovered {
            return Color.secondary.opacity(0.1)
        }
        return Color.clear
    }
}


#if DEBUG
#Preview {
    @Previewable @State var selection: DetailSelection? = nil
    OutlineRowView(
        document: ManuscriptDocument.Document(
            title: "Chapter 1",
            outline: "The hero begins their journey through the mysterious forest.",
            content: "Once upon a time..."
        ),
        viewModel: DocumentViewModel(),
        selection: $selection
    )
}
#endif
