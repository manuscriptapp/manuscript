import SwiftUI
import SwiftData

/// Icon that turns white when background prominence is increased (focused selection)
private struct AdaptiveIcon: View {
    let systemName: String
    let defaultColor: Color
    @Environment(\.backgroundProminence) private var backgroundProminence

    var body: some View {
        Image(systemName: systemName)
            .foregroundStyle(backgroundProminence == .increased ? .white : defaultColor)
    }
}

struct DocumentItemView: View {
    let documentId: UUID
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var detailSelection: DetailSelection?
    @State private var editingTitle: String = ""
    @FocusState private var isTitleFocused: Bool

    /// Look up the current document from the viewModel to ensure we always have fresh data
    private var document: ManuscriptDocument.Document {
        viewModel.findDocument(withId: documentId) ?? ManuscriptDocument.Document(title: "Unknown")
    }

    /// Check if this document is being renamed inline
    private var isBeingRenamed: Bool {
        viewModel.documentIdBeingRenamed == documentId
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

    /// Returns the base icon color, prioritizing iconColor (from Scrivener import) over colorName
    private func baseIconColor(for document: ManuscriptDocument.Document) -> Color {
        // Use icon-specific color if available (from Scrivener import)
        if let hexColor = document.iconColor, let color = Color(hex: hexColor) {
            return color
        }
        // Fallback to document colorName
        return colorForDocument(document)
    }
    
    private func updateIcon(_ iconName: String) {
        viewModel.updateDocumentIcon(document, iconName: iconName)
    }
    
    /// The display title for the document, showing "Untitled Document" in italic when empty
    @ViewBuilder
    private var titleText: some View {
        if document.title.isEmpty {
            Text("Untitled Document")
                .italic()
                .foregroundStyle(.secondary)
        } else {
            Text(document.title)
        }
    }

    /// Inline rename text field shown when the document is being renamed
    @ViewBuilder
    private var inlineRenameField: some View {
        Label {
            TextField("Document name", text: $editingTitle)
                .focused($isTitleFocused)
                .textFieldStyle(.plain)
                .onSubmit {
                    commitRename()
                }
                .onAppear {
                    editingTitle = document.title
                    isTitleFocused = true
                }
                .onChange(of: isTitleFocused) { _, focused in
                    if !focused {
                        commitRename()
                    }
                }
        } icon: {
            AdaptiveIcon(systemName: document.iconName, defaultColor: baseIconColor(for: document))
        }
    }

    private func commitRename() {
        // Guard against being called when not actively renaming
        guard viewModel.documentIdBeingRenamed == documentId else { return }

        let trimmedTitle = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        // Save the title if it's not empty
        if !trimmedTitle.isEmpty {
            viewModel.updateDocument(document, title: trimmedTitle)
        }

        // Clear the rename state
        viewModel.documentIdBeingRenamed = nil
    }

    private var documentLabel: some View {
        Label {
            titleText
        } icon: {
            AdaptiveIcon(systemName: document.iconName, defaultColor: baseIconColor(for: document))
        }
        .id("\(documentId)-\(document.iconName)-\(document.colorName)-\(document.title.isEmpty)")
    }

    var body: some View {
        #if os(iOS)
        NavigationLink(value: DetailSelection.document(document)) {
            documentLabel
        }
        .draggable(DraggableSidebarItem(id: document.id, itemType: .document)) {
            Label(document.title.isEmpty ? "Untitled" : document.title, systemImage: document.iconName)
        }
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
                viewModel.takeSnapshotOfDocument(document)
            }) {
                Label("Take Snapshot", systemImage: "camera.circle")
            }

            Divider()

            Button(action: {
                viewModel.showRenameAlert(for: document)
            }) {
                Label("Rename Document", systemImage: "pencil")
            }

            if viewModel.isDocumentInTrash(document) {
                Button(action: {
                    viewModel.restoreDocumentFromTrash(document)
                }) {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                }

                Button(role: .destructive, action: {
                    viewModel.permanentlyDeleteDocument(document)
                }) {
                    Label("Delete Permanently", systemImage: "trash.slash")
                }
            } else {
                Button(role: .destructive, action: {
                    viewModel.moveDocumentToTrash(document)
                }) {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .trailing) {
            if viewModel.isDocumentInTrash(document) {
                Button(role: .destructive, action: {
                    viewModel.permanentlyDeleteDocument(document)
                }) {
                    Label("Delete", systemImage: "trash.slash")
                }

                Button {
                    viewModel.restoreDocumentFromTrash(document)
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                }
                .tint(.green)
            } else {
                Button {
                    viewModel.showRenameAlert(for: document)
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                .tint(.blue)

                Button(role: .destructive, action: {
                    viewModel.moveDocumentToTrash(document)
                }) {
                    Label("Trash", systemImage: "trash")
                }
            }
        }
        #else
        Group {
            if isBeingRenamed {
                inlineRenameField
                    .tag(DetailSelection.document(document))
            } else {
                documentLabel
                    .tag(DetailSelection.document(document))
                    .draggable(DraggableSidebarItem(id: document.id, itemType: .document)) {
                        Label(document.title.isEmpty ? "Untitled" : document.title, systemImage: document.iconName)
                    }
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
                        viewModel.takeSnapshotOfDocument(document)
                    }) {
                        Label("Take Snapshot", systemImage: "camera.circle")
                    }

                    Divider()

                    Button(action: {
                        editingTitle = document.title
                        viewModel.documentIdBeingRenamed = documentId
                    }) {
                        Label("Rename Document", systemImage: "pencil")
                    }

                    if viewModel.isDocumentInTrash(document) {
                        Button(action: {
                            viewModel.restoreDocumentFromTrash(document)
                        }) {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }

                        Button(role: .destructive, action: {
                            viewModel.permanentlyDeleteDocument(document)
                        }) {
                            Label("Delete Permanently", systemImage: "trash.slash")
                        }
                    } else {
                        Button(role: .destructive, action: {
                            viewModel.moveDocumentToTrash(document)
                        }) {
                            Label("Move to Trash", systemImage: "trash")
                        }
                    }
                }
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
