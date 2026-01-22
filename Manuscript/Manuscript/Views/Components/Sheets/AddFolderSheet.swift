import SwiftUI
import SwiftData

struct AddFolderSheet: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
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
                TextField("Folder Title", text: $title)
                
                Section("Location") {
                    Picker("Parent Folder", selection: $selectedFolder) {
                        folderPickerContent(viewModel.document.rootFolder)
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Add Folder")
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addFolder(to: selectedFolder, title: title)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .presentationBackground(.regularMaterial)
    }
}

