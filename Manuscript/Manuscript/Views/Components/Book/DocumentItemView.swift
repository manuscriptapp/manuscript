import SwiftUI
import SwiftData

struct DocumentItemView: View {
    let documentId: UUID
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var detailSelection: DetailSelection?

    /// Look up the current document from the viewModel to ensure we always have fresh data
    private var document: ManuscriptDocument.Document {
        viewModel.findDocument(withId: documentId) ?? ManuscriptDocument.Document(title: "Unknown")
    }

    private let iconOptions: [(String, String)] = [
        ("Document", "doc.text"),
        ("Chapter", "book"),
        ("Note", "note.text"),
        ("Ideas", "lightbulb"),
        ("Character", "person"),
        ("Location", "mappin"),
        ("Scene", "theatermasks"),
        ("Research", "magnifyingglass"),
        ("Draft", "doc.plaintext"),
        ("Final", "doc.badge.checkmark"),
        ("Important", "exclamationmark.triangle"),
        ("Question", "questionmark.circle"),
        ("Timeline", "clock"),
        ("Plot", "point.topleft.down.curvedto.point.bottomright.up"),
        ("Conflict", "bolt"),
        ("Resolution", "checkmark.circle"),
        ("Flag", "flag"),
        ("Star", "star"),
        ("Heart", "heart"),
        ("Target", "target")
    ]
    
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

    /// Returns the icon color, prioritizing iconColor (from Scrivener import) over colorName
    private func iconColorForDocument(_ document: ManuscriptDocument.Document) -> Color {
        // Use icon-specific color if available (from Scrivener import)
        if let hexColor = document.iconColor, let color = Color(hex: hexColor) {
            return isSelected ? color.darker(by: 0.3) : color
        }
        // Fallback to document colorName
        let baseColor = colorForDocument(document)
        return isSelected && document.colorName == "Brown" ? baseColor.darker(by: 0.4) : baseColor
    }
    
    private func updateIcon(_ iconName: String) {
        viewModel.updateDocumentIcon(document, iconName: iconName)
    }
    
    var body: some View {
        Label {
            Text(document.title)
        } icon: {
            Image(systemName: document.iconName)
                .foregroundStyle(iconColorForDocument(document))
        }
        .id("\(documentId)-\(document.iconName)-\(document.colorName)")
        .tag(DetailSelection.document(document))
        #if !os(macOS)
        .contextMenu {
            Menu("Change Icon") {
                ForEach(iconOptions, id: \.0) { name, icon in
                    Button(action: { updateIcon(icon) }) {
                        Label(name, systemImage: icon)
                            .foregroundStyle(colorForDocument(document))
                    }
                }
            }

            Menu("Change Color") {
                ForEach(colorOptions, id: \.0) { name, color in
                    Button(action: { updateNoteColor(color) }) {
                        HStack {
                            Image(systemName: document.colorName == name ? "checkmark.circle.fill" : "circle.fill")
                                .foregroundColor(color)
                            Text(name)
                        }
                    }
                }
            }

            Divider()

            Button(action: {
                viewModel.showRenameAlert(for: document)
            }) {
                Label("Rename Document", systemImage: "pencil")
            }

            Button(role: .destructive, action: {
                viewModel.deleteDocument(document)
            }) {
                Label("Delete Document", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button {
                viewModel.showRenameAlert(for: document)
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.blue)

            Button(role: .destructive, action: {
                viewModel.deleteDocument(document)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        #else
        .contextMenu {
            Menu("Change Icon") {
                ForEach(iconOptions, id: \.0) { name, icon in
                    Button(action: { updateIcon(icon) }) {
                        Label(name, systemImage: icon)
                            .foregroundStyle(colorForDocument(document))
                    }
                }
            }
            
            Menu("Change Color") {
                ForEach(colorOptions, id: \.0) { name, color in
                    Button(action: { updateNoteColor(color) }) {
                        HStack {
                            Image(systemName: document.colorName == name ? "checkmark.circle.fill" : "circle.fill")
                                .foregroundColor(color)
                            Text(name)
                        }
                    }
                }
            }
            
            Divider()
            
            Button(action: {
                viewModel.showRenameAlert(for: document)
            }) {
                Label("Rename Document", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                viewModel.deleteDocument(document)
            }) {
                Label("Delete Document", systemImage: "trash")
            }
        }
        #endif
    }
    
    private var isSelected: Bool {
        if case .document(let selectedDoc) = detailSelection, 
           selectedDoc.id == document.id {
            return true
        }
        return false
    }
    
    private let colorOptions: [(String, Color)] = [
        ("Yellow", .yellow),
        ("Mint", .mint),
        ("Pink", .pink),
        ("Orange", .orange),
        ("Teal", .teal),
        ("Purple", .purple),
        ("Green", .green),
        ("Blue", .blue),
        ("Red", .red),
        ("Brown", .brown)
    ]
    
    private func updateNoteColor(_ newColor: Color) {
        let colorName = colorOptions.first { $0.1 == newColor }?.0 ?? "Brown"
        viewModel.updateDocumentColor(document, colorName: colorName)
    }
}
