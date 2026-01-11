import SwiftUI
import SwiftData

struct AddFolderSheet: View {
    @ObservedObject var literatiViewModel: LiteratiViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
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
                TextField("Folder Title", text: $title)
                
                Section("Location") {
                    Picker("Parent Folder", selection: $selectedFolder) {
                        folderPickerContent(literatiViewModel.document.rootFolder)
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
                        literatiViewModel.addFolder(to: selectedFolder, title: title)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .padding()
    }
}

