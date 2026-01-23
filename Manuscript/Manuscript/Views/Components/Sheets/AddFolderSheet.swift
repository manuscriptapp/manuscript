import SwiftUI

struct AddFolderSheet: View {
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
            title: "Add Folder",
            cancelAction: { dismiss() },
            confirmAction: {
                viewModel.addFolder(to: selectedFolder, title: title)
                dismiss()
            },
            isConfirmDisabled: title.isEmpty
        ) {
            Section {
                SheetTextField("Title", text: $title, placeholder: "Folder Title")
                SheetPicker(label: "Parent Folder", selection: $selectedFolder) {
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
