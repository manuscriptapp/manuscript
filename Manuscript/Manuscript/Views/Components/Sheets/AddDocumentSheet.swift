import SwiftUI
import SwiftData

struct AddDocumentSheet: View {
    @ObservedObject var literatiViewModel: LiteratiViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var outline = ""
    @State private var notes = ""
    @State private var content = ""
    @State private var selectedFolder: LiteratiFolder
    
    init(document: LiteratiDocument, initialFolder: LiteratiFolder, literatiViewModel: LiteratiViewModel) {
        self.literatiViewModel = literatiViewModel
        self._selectedFolder = State(initialValue: initialFolder)
    }
    
    @ViewBuilder
    func folderPickerContent(_ folder: LiteratiFolder, level: Int = 0) -> AnyView {
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
                        folderPickerContent(literatiViewModel.document.rootFolder)
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
                        literatiViewModel.addDocument(
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
        .padding()
    }
}

