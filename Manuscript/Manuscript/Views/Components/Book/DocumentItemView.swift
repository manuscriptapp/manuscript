import SwiftUI
import SwiftData

struct DocumentItemView: View {
    let document: LiteratiDocument.Document
    @ObservedObject var literatiViewModel: LiteratiViewModel
    @Binding var detailSelection: DetailSelection?
    
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
    
    private func colorForDocument(_ document: LiteratiDocument.Document) -> Color {
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
    
    private func updateIcon(_ iconName: String) {
        literatiViewModel.updateDocumentIcon(document, iconName: iconName)
    }
    
    var body: some View {
        Label {
            Text(document.title)
        } icon: {
            Image(systemName: document.iconName)
                .foregroundStyle(isSelected ? (document.colorName == "Brown" ? colorForDocument(document).darker(by: 0.4) : colorForDocument(document)) : colorForDocument(document))
        }
        .tag(DetailSelection.document(document))
        #if !os(macOS)
        .swipeActions(edge: .trailing) {
            Button {
                literatiViewModel.showRenameAlert(for: document)
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.blue)
            
            Button(role: .destructive, action: {
                literatiViewModel.deleteDocument(document)
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
                        Label(name, systemImage: document.colorName == name ? "checkmark.circle.fill" : "circle.fill")
                            .foregroundStyle(color)
                    }
                }
            }
            
            Divider()
            
            Button(action: {
                literatiViewModel.showRenameAlert(for: document)
            }) {
                Label("Rename Document", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                literatiViewModel.deleteDocument(document)
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
        literatiViewModel.updateDocumentColor(document, colorName: colorName)
    }
}
