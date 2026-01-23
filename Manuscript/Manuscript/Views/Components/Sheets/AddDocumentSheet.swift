import SwiftUI

struct AddDocumentSheet: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedFolder: ManuscriptFolder

    init(viewModel: DocumentViewModel, initialFolder: ManuscriptFolder? = nil) {
        self.viewModel = viewModel
        self._selectedFolder = State(initialValue: initialFolder ?? viewModel.document.rootFolder)
    }

    var body: some View {
        SheetForm(
            title: "Add Document",
            cancelAction: { dismiss() },
            confirmAction: {
                viewModel.addDocument(
                    to: selectedFolder,
                    title: title,
                    outline: "",
                    notes: "",
                    content: ""
                )
                dismiss()
            },
            isConfirmDisabled: title.isEmpty
        ) {
            Section {
                SheetTextField("Title", text: $title, placeholder: "Document Title")
                SheetPicker(label: "Folder", selection: $selectedFolder) {
                    folderPickerContent(viewModel.document.rootFolder)
                }
            }
        }
    }

    @ViewBuilder
    private func folderPickerContent(_ folder: ManuscriptFolder, level: Int = 0) -> AnyView {
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
}
