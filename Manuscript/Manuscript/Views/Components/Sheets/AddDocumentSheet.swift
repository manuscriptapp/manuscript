import SwiftUI
import SwiftData

struct AddDocumentSheet: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var outline = ""
    @State private var notes = ""
    @State private var content = ""
    @State private var selectedFolder: ManuscriptFolder

    init(viewModel: DocumentViewModel, initialFolder: ManuscriptFolder? = nil) {
        self.viewModel = viewModel
        self._selectedFolder = State(initialValue: initialFolder ?? viewModel.document.rootFolder)
    }

    @ViewBuilder
    func folderPickerContent(_ folder: ManuscriptFolder, level: Int = 0) -> AnyView {
        AnyView(
            Group {
                HStack {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    Text(folder.title)
                }
                .padding(.leading, CGFloat(level * 20))
                .tag(folder)
                
                ForEach(folder.subfolders) { subfolder in
                    folderPickerContent(subfolder, level: level + 1)
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Document Title", text: $title)
                
                Section("Location") {
                    Picker("Folder", selection: $selectedFolder) {
                        folderPickerContent(viewModel.document.rootFolder)
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Outline/Synopsis") {
                    TextEditor(text: $outline)
                        .frame(minHeight: 100)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Document")
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addDocument(
                            to: selectedFolder,
                            title: title,
                            outline: outline,
                            notes: notes,
                            content: content
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .presentationBackground(.regularMaterial)
    }
}

