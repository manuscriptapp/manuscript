import SwiftUI
import SwiftData

struct DetailContentView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

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
            if let freshDocument = viewModel.findDocument(withId: document.id) {
                DocumentDetailView(document: freshDocument, viewModel: viewModel)
            } else {
                DocumentDetailView(document: document, viewModel: viewModel)
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
    DetailContentView(
        viewModel: DocumentViewModel(),
        selection: $selection
    )
}
#endif
