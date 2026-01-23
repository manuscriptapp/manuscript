import SwiftUI

/// Index card view for documents in corkboard mode
struct CorkboardCardView: View {
    let document: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    private var isSelected: Bool {
        if case .document(let doc) = selection {
            return doc.id == document.id
        }
        return false
    }

    var body: some View {
        Button {
            viewModel.expandToDocument(document)
            selection = .document(document)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header bar with icon and title
                HStack(spacing: 8) {
                    Image(systemName: document.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(colorForDocument(document))

                    Text(document.title.isEmpty ? "Untitled Document" : document.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(document.title.isEmpty ? .secondary : .primary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(cardHeaderBackground)

                Divider()

                // Synopsis body
                VStack(alignment: .leading, spacing: 0) {
                    if document.synopsis.isEmpty {
                        Text("No synopsis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Text(document.synopsis)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(6)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Divider()

                // Footer with metadata
                HStack {
                    Text("\(document.wordCount.formatted()) words")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(document.creationDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        .draggable(DraggableSidebarItem(id: document.id, itemType: .document))
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

    private var cardBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    private var cardHeaderBackground: Color {
        colorForDocument(document).opacity(0.15)
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
}
