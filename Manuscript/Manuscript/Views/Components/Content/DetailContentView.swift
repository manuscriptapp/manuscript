import SwiftUI
import SwiftData

struct DetailContentView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?
    let fileURL: URL?
    @Binding var splitEditorState: SplitEditorState

    var body: some View {
        if let currentSelection = selection {
            detailContent(for: currentSelection)
        }
    }

    @ViewBuilder
    private func detailContent(for currentSelection: DetailSelection) -> some View {
        switch currentSelection {
        case .projectInfo:
            ProjectInfoView(viewModel: viewModel)
        case .characters:
            CharactersView(viewModel: viewModel)
        case .locations:
            LocationsView(viewModel: viewModel)
        case .writingHistory:
            WritingHistoryView(writingHistory: viewModel.document.writingHistory)
        case .folder(let folder):
            FolderDetailView(folder: folder, viewModel: viewModel, selection: $selection)
        case .document(let document):
            // Look up fresh document from view model to get latest content
            // Use .id() to force SwiftUI to create a new view when document changes
            if let freshDocument = viewModel.findDocument(withId: document.id) {
                SplitEditorContainerView(
                    primaryDocument: freshDocument,
                    viewModel: viewModel,
                    fileURL: fileURL,
                    splitEditorState: $splitEditorState
                )
                .id(freshDocument.id)
            } else {
                SplitEditorContainerView(
                    primaryDocument: document,
                    viewModel: viewModel,
                    fileURL: fileURL,
                    splitEditorState: $splitEditorState
                )
                .id(document.id)
            }
        case .character(let character):
            CharacterDetailView(character: character, viewModel: viewModel)
        case .location(let location):
            ManuscriptLocationDetailView(viewModel: viewModel, location: location)
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: DetailSelection? = .projectInfo
    @Previewable @State var splitState = SplitEditorState()
    DetailContentView(
        viewModel: DocumentViewModel(),
        selection: $selection,
        fileURL: nil,
        splitEditorState: $splitState
    )
}
#endif
