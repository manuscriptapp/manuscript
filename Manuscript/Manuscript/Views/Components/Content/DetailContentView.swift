import SwiftUI
import SwiftData

struct DetailContentView: View {
    @ObservedObject var viewModel: DocumentViewModel
    let selection: DetailSelection

    var body: some View {
        detailContent(for: selection)
    }

    @ViewBuilder
    private func detailContent(for selection: DetailSelection) -> some View {
        switch selection {
        case .projectInfo:
            ProjectInfoView(viewModel: viewModel)
        case .characters:
            CharactersView(viewModel: viewModel)
        case .locations:
            LocationsView(viewModel: viewModel)
        case .folder(let folder):
            FolderDetailView(folder: folder, viewModel: viewModel)
        case .document(let document):
            DocumentDetailView(document: document, viewModel: viewModel)
        case .character(let character):
            CharacterDetailView(character: character, viewModel: viewModel)
        case .location(let location):
            ManuscriptLocationDetailView(viewModel: viewModel, location: location)
        }
    }
}

#if DEBUG
#Preview {
    DetailContentView(
        viewModel: DocumentViewModel(),
        selection: .projectInfo
    )
}
#endif
